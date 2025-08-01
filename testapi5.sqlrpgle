**FREE
        ctl-opt debug option(*nodebugio:*srcstmt) datfmt(*iso-) timfmt(*iso.);
        ctl-opt DftActGrp(*no) bnddir('QC2LE':'WEBDIR');

         // Send data outbond - Used to send response
         DCL-PR WriteToWeb Extproc('QtmhWrStout');
            Datavar char(65536) options(*varsize);
            DatavarLen int(10) const;
            Errcode char(8000) options(*varsize);
         End-pr;

         // Read the incoming request
         dcl-pr getrequest extproc('QtmhRdStin');
           buffer       char(32767) options(*varsize);
           bufLen       int(10) const;
           bytesRead    int(10);
           errorCode    like(errorCode);
         end-pr;

         // Get environment variables
         dcl-pr getEnv Pointer ExtProc('getenv');
             *N Pointer value options(*string);
         End-pr;

         // Translate ASCII to EBCDIC
         dcl-pr translate extpgm('QDCXLATE');
            *N Packed(5) const;
            *N CHAR(32766) OPTIONS(*VARSIZE);
            *N CHAR(10) CONST;
         end-pr;

         dcl-s EBCDATA CHAR(32766);

         dcl-s inputBuffer char(32767);
         dcl-s bytesRead   int(10);
         dcl-s buflen      int(10);
         dcl-s errorCode   char(8) inz(*loval);

         DCL-S outData1 char(2000);
         DCL-S reqMethod Char(10);

         // End of line character
         DCL-C CRLF CONST(x'0d25');

         dcl-s header char(1000);

         dcl-ds err;
           byteProv int(10) inz(0);
           byteAvail int(10);
         end-ds;

        exec sql set option commit = *none, closqlcsr = *endmod;

        reqMethod = %str(GetEnv('REQUEST_METHOD'));
        If reqMethod = 'POST';

         // Read the input data from standard input
         getrequest(inputBuffer: %size(inputBuffer): bytesRead: errorCode);
         if (bytesRead > 0);
           outData1 = '{"success":true}';

          // This place will be used to process the incomming request like storing to DB

         else;
           outData1 = '{"success":false}';
         endif;
        Else;
          outData1= 'This was a get request';
        Endif;

        // Form the header
        header = 'Status: 200 OK' + CRLF +
        'Content-type: text/plain' + CRLF + CRLF;
        writeToWeb( header : %len(header) : err);


        // Send response
        WriteToWeb(outData1: %len(outData1): err);

        *inlr = *ON;
