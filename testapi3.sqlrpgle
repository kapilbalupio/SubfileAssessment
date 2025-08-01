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
         dcl-s jsonString varchar(1000);
         dcl-s jsonElement varchar(200);
         dcl-s Wk_Desc char(30);
         dcl-s Wk_itemno   zoned(5);

         dcl-c jsonStart '{ "Item": [';
         dcl-c jsonEnd '] }';

         // End of line
         DCL-C CRLF CONST(x'0d25');

         dcl-s header char(1000);

         dcl-ds err;
           byteProv int(10) inz(0);
           byteAvail int(10);
         end-ds;
         exec sql set option commit = *none, closqlcsr = *endmod;

         // form the header
         header = 'Status: 200 OK' + CRLF +
                  'Content-type: text/plain' + CRLF + CRLF;
         writeToWeb( header : %len(header) : err);
         exec sql declare c1 cursor for
                                select ITMNO, ITMDESC from ITMMASTP;

         exec sql open c1;
         jsonString = jsonStart;

         dow sqlcod = 0;
            exec sql fetch c1 into :WK_Itemno, :WK_DESC;

            if sqlcod = 0;
               jsonElement = '{ "itemno": "' + %char(Wk_Itemno) + '", ' +
                                 '"desc": "' + %trim(wk_desc) + '" }';


                 if %len(%trim(jsonString)) > %len(jsonStart);
                    jsonString += ', ';
                 endif;

                 jsonString += jsonElement;
            endif;
         enddo;
         exec sql close c1;

         jsonString += jsonEnd;
         outData1 = jsonString;

         // Send response
         WriteToWeb(outData1: %len(outData1): err);

         *inlr = *ON;
