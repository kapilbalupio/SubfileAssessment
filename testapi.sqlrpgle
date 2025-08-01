**FREE
        ctl-opt debug option(*nodebugio:*srcstmt) datfmt(*iso-) timfmt(*iso.);
        ctl-opt DftActGrp(*no) bnddir('QC2LE':'WEBDIR');

         // Send data outbond - response
         DCL-PR WriteToWeb Extproc('QtmhWrStout');
            Datavar char(65536) options(*varsize);
            DatavarLen int(10) const;
            Errcode char(8000) options(*varsize);
         End-pr;

         // End of line
         DCL-C CRLF CONST(x'0d25');

         dcl-s header char(1000);
         dcl-s greet char(20) inz(*blanks);

         dcl-ds err;
           byteProv int(10) inz(0);
           byteAvail int(10);
         end-ds;

         // form the header
         header = 'Status: 200 OK' + CRLF +
                        'Content-type: text/plain' + CRLF + CRLF;
         writeToWeb( header : %len(header) : err);

         // dump the message
         greet = 'Hello World DEMO';
         WriteToWeb( greet : %len(greet) : err);

         *inlr = *ON;
