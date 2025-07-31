**FREE
        ctl-opt debug option(*nodebugio:*srcstmt) datfmt(*iso-) timfmt(*iso.);
        ctl-opt DftActGrp(*no) bnddir('QC2LE':'WEBDIR');

         // Send data outbond
         DCL-PR WriteToWeb Extproc('QtmhWrStout');
            Datavar char(65536) options(*varsize);
            DatavarLen int(10) const;
            Errcode char(8000) options(*varsize);
         End-pr;
         DCL-S outData varchar(2000);
         DCL-S outData1 char(2000);

         DCL-C CRLF CONST(x'0d25');
         dcl-s header char(1000);
         dcl-s greet char(20) inz(*blanks);
         dcl-ds err;
           byteProv int(10) inz(0);
           byteAvail int(10);
         end-ds;
        exec sql set option commit = *none, closqlcsr = *endmod;

           // form the header
               header = 'Status: 200 OK' + CRLF +
                        'Content-type: text/plain' + CRLF + CRLF;
               writeToWeb( header : %len(header) : err);


        //    exec sql
        //  select JSON_ARRAYAGG(json_object('ItemNo' value itmno,
         // 'Desc' value Itmdesc) )  into :outData
        //  from itmmastp;
        exec sql sELECT      JSON_OBJECT('ITEMS'
                     VALUE JSON_ARRAYAGG(
                       JSON_OBJECT('ItemNo' : ITMNO,
                                   'Desc' : itmdesc)))   into :outData
              FROM itmmastp;
            outData1 =outData;
           // Send response
           WriteToWeb(outData1: %len(outData): err);

           *inlr = *ON;
