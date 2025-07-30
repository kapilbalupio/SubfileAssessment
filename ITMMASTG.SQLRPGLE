     **FREE
        // Description... ITEM MASTER FILE MAINTENANCE PROGRAM
        // File Name..... ITMMASTG.SQLRPGLE
        // Developer........ Kapil Balu
        // Date.......... 25th July 2025
        //
        // Compile Instructions:
        //
        // CRTSQLRPGI SRCFILE(*LIBL/QRPGLESRC)
        // SRCMBR(ITMMASTG)
        // OBJTYPE(*MODULE)
        //
        // CRTPGM PGM(*LIBL/ITMMASTG)
        //
        ctl-opt debug option(*nodebugio:*srcstmt) datfmt(*iso-) timfmt(*iso.) ;

        dcl-f ITMMASTD workstn sfile(SFL01:rrn) indDs(dspf);

        dcl-s p_Indicators pointer inz(%addr(*in));

        dcl-ds dspf qualified based(p_Indicators);
            help ind pos(01);
            exit ind pos(03);
            refresh ind pos(05);
            ADDREC  ind pos(06);
            previous ind pos(12);
            pageup ind pos(25);
            pagedown ind pos(26);
            sflclr ind pos(32);
            sfldsp ind pos(30);
            sflctl ind pos(31);
            sflEnd ind pos(35);
            sflnxtchg ind pos(36);
            opterror  ind pos(37);
            itemDescAddError ind pos(38);
            itemQtyAddError ind pos(39);
            itemPriceAddError ind pos(40);
        end-ds;

        dcl-ds dsp_fields extname('ITMMASTP') end-ds;

        DCL-DS pgm_stat PSDS;
             user1 CHAR(10) POS(254);
             pgm    *proc;
        END-DS;

        DCL-S  closeCursor ind INZ(*OFF);
        DCL-C  True const(*ON);
        DCL-C  False const(*OFF);

        dcl-s rrn like(sflrrn);
        dcl-s previousPosition like(position);
        dcl-s pagesize zoned(2) inz(5);
        dcl-s position zoned(5);
        dcl-s wk_query CHAR(200);
        dcl-s WK_DESC  LIKE(DESC);
        dcl-s searchPattern CHAR(100);
        dcl-s WK_MaxItemNo  like(ITMNO);
        Dcl-S Wk_Date Zoned(8:0);

        // Start of program logic
        exec sql set option commit = *none, closqlcsr = *endmod;

        // Switch on display file refresh for initial load
        dspf.refresh = True;
        clear posto;
        clear DESC;
        clear WK_DESC;
        closeCursor  = False;

        dou dspf.exit or dspf.previous;
            Select;
            When dspf.refresh or (posto <> *zeros and
                not dspf.pageup and not dspf.pagedown) OR
                ((DESC <> *blanks OR WK_DESC <> *BLANKS)
                  and not dspf.pageup and not dspf.pagedown);

                If desc = *blanks and wk_desc <> *blanks;
                   closeCursor = True;
                Endif;

                WK_DESC = DESC;

                clear position;
                clearSubfile();
                setPosition();
                loadSubfile();
            When   dspf.pageUp;
                clear posto;
                exec sql close mycursor;
                setPosition();
                pageUp();
            When   dspf.pagedown;
                clear posto;
                 pageDown();
            When   dspf.addrec;
              LoadAddScreen();

            Other;

              // Loop for validation of subfile options
              READC  SFL01;
              Dow not %eof();
                dspf.opterror = False;
                If Opt <> '2' and  Opt <> ' ' and Opt <> '3' and Opt <> '4'
                and Opt <> '5';
                  ERRORMSG = 'Option not valid';
                  dspf.opterror = True;
                Endif;

                dspf.sflnxtchg = True;
                Update SFL01;
                READC  SFL01;

              Enddo;

              // Process subfile options
              READC  SFL01;
              Dow not %eof();
                Select;
                When Opt = '2';
                  LoadEditScreen();

                When Opt = '5';
                  LoadDisplayScreen();

                Endsl;

                Update SFL01;
                READC  SFL01;

              Enddo;

            Endsl;

            showSubfile();

        enddo;

        *inlr = True;

        // Clear Subfile procedure...
        dcl-proc clearSubfile;

            dspf.sflEnd = False;
            dspf.sflclr = True;
            write ctl01;
            dspf.sflclr = False;

        end-proc;
        // Build Subfile procedure...
        dcl-proc loadSubfile;

            dspf.sflEnd = False;
            rrn = 0;

            exec sql fetch next from mycursor into :dsp_fields;

            previousPosition = ITMNO;

            dow sqlcode >= 0 and sqlcode < 100;
                rrn += 1;
                write SFL01;
                if rrn = pagesize;
                    leave;
                endif;

                exec sql fetch next from mycursor into :dsp_fields;
            enddo;
            // if we didnt load a full page then set END OF SUBFILE
            if rrn < pagesize;
                dspf.sflEnd = True;
            endif;

        end-proc;
        // Display Subfile procedure...
        dcl-proc showSubfile;

            if rrn > 0;
                dspf.sfldsp = True;
            else;
                dspf.sfldsp = False;
                errormsg = 'No data Available!';
            endif;

            dspf.sflctl = True;

            write FOOTER;
            write HEADER;
            exfmt ctl01;

            clear ERRORMSG;

        end-proc;

        // Declare cursor procedure...
        dcl-proc setPosition;

            Clear wk_query;
            If posto  <> *zeros OR DESC <> *BLANKS OR closeCursor;
               exec sql close mycursor;
               position  =  Posto;
            Endif;
            If desc <> *Blanks;
               searchPattern  = '%'+%upper(%trim(desc))+'%';
               wk_query  = 'select * from ITMMASTP' +
               ' where ITMNO >= ' +%char(position)+'  and upper(ITMDESC) '+
               ' LIKE '''+%trim(searchPattern)+''' order by ITMNO';
            Else;
              Wk_Query = 'select * from ITMMASTP '+
                  'where ITMNO >=  '+%char(position)+
               ' order by ITMNO';
            Endif;

            EXEC SQL PREPARE S1 FROM :wk_query;
            EXEC sql declare mycursor scroll cursor for S1;

        //  Else;
        //    exec sql declare mycursor scroll cursor for
        //    select * from ITMMASTP where ITMNO >= :position
        //    order by ITMNO for read only;
        //  Endif;

            exec sql open mycursor;

        end-proc;

        // Page up procedure...
        dcl-proc pageUp;

            // set start cursor RRN at first row of previous page
            if rrn = pagesize;
                position = previousPosition;
            else;
                clear position;
            endif;

            // Build the subfile starting at *position*
            clearSubfile();
            loadSubfile();

            // If the cursor already in the top the list
            if rrn <= pagesize;
                errormsg = 'Start of the list reached';
            endif;
        end-proc;

        // Page down procedure...
        dcl-proc pageDown;

            // Build the subfile starting at *position*
            clearSubfile();
            loadSubfile();

            // If more to read then show sflend
            if rrn < pagesize;
                errormsg = 'Bottom of the list reached.';
            endif;

        end-proc;

        // Load edit screen
        dcl-proc LoadEditScreen;

            ITMNOU  =  ITMNO;
            ITMDESCU = ITMDESC ;
            ITMQTYU =  ITMQTY;
            ITMPRICEU = ITMPRICE;
            dou dspf.exit or dspf.previous;
              WRITE FOOTER1;
              WRITE HEADER;
              Exfmt ITMUPDR;

            enddo;

        end-proc;

        // Load display screen
        dcl-proc LoadDisplayScreen;

            ITMNOD  =  ITMNO;
            ITMDESCD = ITMDESC ;
            ITMQTYD =  ITMQTY;
            ITMPRICED = ITMPRICE;
            dou dspf.exit or dspf.previous;
              WRITE FOOTER1;
              WRITE HEADER;
              Exfmt ITMDSPR;

            enddo;

        end-proc;

        // Load Add screen
        dcl-proc LoadAddScreen;
            dou dspf.exit or dspf.previous;
              clear ITMDESCA;
              clear ITMQTYA;
              clear ITMPRICEA;
              write footer1;
              write header;
              exfmt ITMADDR;

              Clear Errormsg1;
              dspf.itemPriceAddError =False;
              dspf.itemDescAddError  =False;
              dspf.itemQtyAddError   =False;

              If ITMDESCA  = *Blanks;
                Errormsg1='Please enter Item Description';
                dspf.itemDescAddError = True;
              Endif;

              If ITMQTYA   = *Zeros;
                Errormsg1='Please enter Item Quantity';
                dspf.itemQtyAddError = True;
              Endif;

              If ITMPRICEA = *Zeros;
                Errormsg1='Please enter Item Price';
                dspf.itemPriceAddError = True;
              Endif;

              // Add record if no errors
              If Errormsg1 = *Blanks;
                // Increment item no
                Exec sql select max(ITMNO) INTO :WK_MaxItemNo from ITMMASTP;
                If sqlcod = 0;
                   WK_MaxItemNo += 1;
                   Wk_date = %Dec(%Char(%Date():*ISO0):8:0);
                   Exec sql Insert into ITMMASTP (ITMNO,ITMDESC,ITMQTY,ITMPRICE,
                    ITMCRTBY, ITMCRTON, ITMUPDBY, ITMUPDON, ITMCRTPGM,ITMUPDPGM)
                    Values( :WK_MaxItemNo, :ITMDESCA, :ITMQTYA, :ITMPRICEA,
                            :user1, :wk_date, :user1, :wk_date,
                            :pgm, :pgm);
                    If sqlcod = 0;
                      Errormsg1 ='Inserted successfully';
                    Else;
                      Errormsg1 ='Unexpected error. Inform IT team';
                    Endif;
                Else;
                  Errormsg1 ='Unexpected error. Inform IT team';
                Endif;

              Endif;


            Enddo;
        end-proc;
        // -- end of Program --
