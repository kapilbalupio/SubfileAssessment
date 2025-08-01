**FREE
        ctl-opt debug option(*nodebugio:*srcstmt) datfmt(*iso-) timfmt(*iso.);
        ctl-opt DftActGrp(*no) bnddir('QC2LE':'WEBDIR');

        // Send data outbond
        DCL-PR WriteToWeb Extproc('QtmhWrStout');
            Datavar char(65536) options(*varsize);
            DatavarLen int(10) const;
            Errcode char(8000) options(*varsize);
        End-pr;

         DCL-S outData1 char(2000);
         dcl-s htmlString varchar(1000);

         // End of line hexa value
         DCL-C CRLF CONST(x'0d25');
         dcl-s header char(1000);

         dcl-ds itemData extname('ITMMASTP') qualified end-ds;

         dcl-ds err;
           byteProv int(10) inz(0);
           byteAvail int(10);
         end-ds;

        // Read from db
        exec sql set option commit = *none, closqlcsr = *endmod;

        // form the header
        header = 'Status: 200 OK' + CRLF +
                 'Content-type: text/HTML' + CRLF + CRLF;
                 writeToWeb( header : %len(header) : err);
        exec sql declare c1 cursor for select * from ITMMASTP;

        exec sql open c1;

        htmlString = '<html><body><h2>Item List</h2> '+
                        '<table><tr><th>Item No</th><th>Description</th>'+
                        '<th>Item Quantity</th><th>Item Price</th>'+
                       '</tr>';

        dow sqlcod = 0;
          exec sql fetch c1 into :itemData;

          if sqlcod = 0;
                 htmlString += '<tr><td>'+  %char(itemData.itmno)+ '</td>' +
                                   '<td>'+%trim(itemData.itmdesc)+' </td>'+
                                   '<td>'+%char(itemData.itmqty)+' </td>'+
                              '<td>'+%char(itemData.itmprice)+' </td></tr>';


          endif;
        enddo;

        exec sql close c1;

        htmlString += '</table></body></html>';
        outData1 = htmlString;

        // Send response
        WriteToWeb(outData1: %len(outData1): err);

        *inlr = *ON;
