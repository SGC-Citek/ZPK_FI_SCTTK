CLASS zcl_fi_scttk_manage DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_fi_scttk_manage.
    TYPES: tty_data     TYPE STANDARD TABLE OF zi_fi_scttk,
           tty_data_out TYPE TABLE OF zi_fi_scttk.
    METHODS get_data
      IMPORTING io_request TYPE REF TO if_rap_query_request
      EXPORTING et_data    TYPE tty_data_out.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: go_instance TYPE REF TO zcl_fi_scttk_manage.

    DATA: mt_data        TYPE tty_data,
          mt_parameter   TYPE if_rap_query_request=>tt_parameters,
          mt_filter_cond TYPE if_rap_query_filter=>tt_name_range_pairs.
ENDCLASS.



CLASS ZCL_FI_SCTTK_MANAGE IMPLEMENTATION.


  METHOD get_data.
    DATA: lv_ledger              TYPE fins_ledger,
          lv_increv              TYPE zde_boolean,
          lv_currencytype        TYPE zde_curr_type,
          lv_flagsum             TYPE zde_boolean,
          lr_companycode         TYPE RANGE OF bukrs,
          lr_fiscalyear          TYPE RANGE OF fis_gjahr_no_conv,
          lv_fiscalyear          TYPE fis_gjahr_no_conv,
          lr_fiscalperiod        TYPE RANGE OF fins_fiscalperiod,
          lr_postingdate         TYPE RANGE OF fis_budat,
          lr_glaccount           TYPE RANGE OF zde_racct,
          lr_offsettingaccount   TYPE RANGE OF zde_racct,
          lr_transactioncurrency TYPE RANGE OF waers.


    DATA: lt_data_raw_all TYPE TABLE OF zi_fi_scttk,
          lt_data_raw     TYPE TABLE OF zi_fi_scttk,
          lt_data_beg     TYPE TABLE OF zi_fi_scttk,
          lt_data_inp     TYPE TABLE OF zi_fi_scttk,
          lt_data         TYPE TABLE OF zi_fi_scttk,
          lt_data_sum_beg TYPE TABLE OF zi_fi_scttk,
          lt_data_sum_inp TYPE TABLE OF zi_fi_scttk,
          lt_data_sum_end TYPE TABLE OF zi_fi_scttk,
          ls_data         TYPE zi_fi_scttk.

    " get filter by parameter -----------------------
    DATA(lt_paramater) = io_request->get_parameters( ).
    TRY.
        DATA(lt_filter_cond) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_sel_option).
    ENDTRY.

    IF mt_parameter     IS NOT INITIAL AND lt_paramater   = mt_parameter    AND
       mt_filter_cond   IS NOT INITIAL AND lt_filter_cond = mt_filter_cond  AND
       mt_data          IS NOT INITIAL.
      et_data = mt_data.
    ELSE.
      IF lt_paramater IS NOT INITIAL.
        LOOP AT lt_paramater REFERENCE INTO DATA(ls_parameter).
          CASE ls_parameter->parameter_name.
            WHEN 'P_LEDGER'.
              lv_ledger       = ls_parameter->value.
            WHEN 'P_INCREV'.
              lv_increv       = ls_parameter->value.
            WHEN 'P_CURRENCYTYPE'.
              lv_currencytype = ls_parameter->value.
            WHEN 'P_FLAGSUM'.
              lv_flagsum      = ls_parameter->value.
          ENDCASE.
        ENDLOOP.
      ENDIF.
      IF lt_filter_cond IS NOT INITIAL.
        LOOP AT lt_filter_cond REFERENCE INTO DATA(ls_filter_cond).
          CASE ls_filter_cond->name.
            WHEN 'COMPANYCODE'.
              lr_companycode          = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN 'FISCALYEAR'.
              lr_fiscalyear           = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN 'FISCALPERIOD'.
              lr_fiscalperiod         = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN 'POSTINGDATE'.
              lr_postingdate          = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN 'GLACCOUNT'.
              lr_glaccount            = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN 'OFFSETTINGACCOUNT'.
              lr_offsettingaccount    = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN 'TRANSACTIONCURRENCY'.
              lr_transactioncurrency  = CORRESPONDING #( ls_filter_cond->range[] ) .
            WHEN OTHERS.
          ENDCASE.
        ENDLOOP.
      ENDIF.

      if lv_currencytype = 'I' or lv_currencytype = 'T'.
        CLEAR: lr_transactioncurrency.
        lr_transactioncurrency = VALUE #( sign = 'I' option = 'EQ' ( low = 'VND' ) ).
      ENDIF.

      " get filter by parameter -----------------------

      DATA: lv_fromdate TYPE dats,
            lv_todate   TYPE dats.

      CHECK lr_postingdate IS NOT INITIAL.

      lv_fromdate = lr_postingdate[ 1 ]-low.
      lv_todate   = lr_postingdate[ 1 ]-high.

      lv_fiscalyear = lr_fiscalyear[ 1 ]-low.

      SELECT
        companycode,
        glaccount,
        glaccountlongname,
        accountingdocument,
        ledgergllineitem,
        fiscalyear,
        fiscalperiod,
        postingdate,
        documentdate,
        offsettingaccount,
        transactioncurrency,
        companycodecurrency,
        financialaccounttype,
        code,
        text,
        CASE WHEN code IS NOT INITIAL
          THEN concat_with_space( code,concat_with_space( '-', text,1 ) ,1 )
          ELSE ' '
        END AS objecttext,
        diengiai,
        product,
        productname,
        masterfixedasset,
        fixedasset,
        fixedassetdescription,
        costcenter,
        costcentername,
        customer,
        supplier,
        assignmentreference,
        SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
        SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
        SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
        SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
        FROM zi_fi_scttk_sum( p_ledger = @lv_ledger, p_increv = @lv_increv, p_currencytype = @lv_currencytype, p_flagsum = @lv_flagsum )
        WHERE companycode         IN @lr_companycode
          AND fiscalyear          LE @lv_fiscalyear
          AND fiscalperiod        IN @lr_fiscalperiod
          AND postingdate         LE @lv_todate
          AND glaccount           IN @lr_glaccount
          AND offsettingaccount   IN @lr_offsettingaccount
*          AND ( glaccount           IN @lr_glaccount OR glaccount           IN @lr_offsettingaccount )
*          AND ( offsettingaccount   IN @lr_offsettingaccount OR offsettingaccount   IN @lr_glaccount )
          AND transactioncurrency IN @lr_transactioncurrency
        GROUP BY
        companycode,
        glaccount,
        glaccountlongname,
        accountingdocument,
        ledgergllineitem,
        fiscalyear,
        fiscalperiod,
        postingdate,
        documentdate,
        offsettingaccount,
        transactioncurrency,
        companycodecurrency,
        financialaccounttype,
        code,
        text,
        diengiai,
        product,
        productname,
        masterfixedasset,
        fixedasset,
        fixedassetdescription,
        costcenter,
        costcentername,
        customer,
        supplier,
        assignmentreference
        INTO CORRESPONDING FIELDS OF TABLE @lt_data_raw_all.

      CHECK sy-subrc = 0.

      SELECT
        profile~accountingdocument,
        profile~accountingdocumentitem,
        profile~fiscalyear,
        profile~companycode,
        profile~financialaccounttype,
        profile~account,
        profile~accountnname AS accountname
        FROM zcore_i_profile_fidoc_v2 AS profile
        INNER JOIN @lt_data_raw_all AS data
        ON  profile~accountingdocument   = data~accountingdocument
        AND profile~fiscalyear           = data~fiscalyear
        AND profile~companycode          = data~companycode
        INTO TABLE @DATA(lt_data_pf).
      IF sy-subrc EQ 0.
        SORT lt_data_pf BY accountingdocument fiscalyear companycode financialaccounttype.
      ENDIF.

      SELECT DISTINCT supplier
        FROM @lt_data_raw_all AS data
        WHERE data~supplier IS NOT INITIAL
          INTO TABLE @DATA(lt_supplier).
      IF sy-subrc EQ 0.
        SELECT
          profile~supplier,
          profile~supplierfullname
          FROM zcore_i_profile_supplier AS profile
          INNER JOIN @lt_supplier AS data
          ON profile~supplier = data~supplier
          ORDER BY profile~supplier
          INTO TABLE @DATA(lt_supplier_name).
      ENDIF.

      SELECT DISTINCT customer
        FROM @lt_data_raw_all AS data
        WHERE data~customer IS NOT INITIAL
          INTO TABLE @DATA(lt_customer).
      IF sy-subrc EQ 0.
        SELECT
          profile~customer,
          profile~customerfullname
          FROM zcore_i_profile_customer AS profile
          INNER JOIN @lt_customer AS data
          ON profile~customer = data~customer
          ORDER BY profile~customer
          INTO TABLE @DATA(lt_customer_name).
      ENDIF.

      SELECT *
      FROM @lt_data_raw_all AS data
      WHERE glaccount           IN @lr_glaccount
        AND offsettingaccount   IN @lr_offsettingaccount
      INTO TABLE @lt_data_raw.

      SORT lt_data_raw_all BY companycode accountingdocument fiscalyear glaccount offsettingaccount.

      LOOP AT lt_data_raw ASSIGNING FIELD-SYMBOL(<lfs_data_raw>).
        IF <lfs_data_raw>-financialaccounttype EQ 'D' OR
           <lfs_data_raw>-financialaccounttype EQ 'K'.
          IF <lfs_data_raw>-code IS INITIAL.
            READ TABLE lt_data_pf INTO DATA(ls_data_pf)
              WITH KEY accountingdocument = <lfs_data_raw>-accountingdocument
                       fiscalyear         = <lfs_data_raw>-fiscalyear
                       companycode        = <lfs_data_raw>-companycode BINARY SEARCH.
            IF sy-subrc EQ 0.
              <lfs_data_raw>-code = ls_data_pf-account.
              <lfs_data_raw>-text = ls_data_pf-accountname.
              CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
            ENDIF.
          ENDIF.
        ELSEIF <lfs_data_raw>-financialaccounttype EQ 'A'.
          <lfs_data_raw>-code = <lfs_data_raw>-masterfixedasset.
          <lfs_data_raw>-text = <lfs_data_raw>-fixedassetdescription.
          CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
        ELSEIF <lfs_data_raw>-financialaccounttype EQ 'M'.
          <lfs_data_raw>-code = <lfs_data_raw>-product.
          <lfs_data_raw>-text = <lfs_data_raw>-productname.
          CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
        ELSEIF <lfs_data_raw>-financialaccounttype EQ 'S'.
          CLEAR: <lfs_data_raw>-code,
                 <lfs_data_raw>-text,
                 <lfs_data_raw>-objecttext.
*            o    Ưu tiên 1.1: Nếu [Field] Material <> null
*               Lấy mã: [Field] Material.
*               Lấy tên: Vào [CDS] I_ProductText, lấy [Field] ProductName
          IF <lfs_data_raw>-product IS NOT INITIAL.
            <lfs_data_raw>-code = <lfs_data_raw>-product.
            <lfs_data_raw>-text = <lfs_data_raw>-productname.
            CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
*            o Ưu tiên 1.2: Nếu [Field] MasterFixedAsset <> null
*               Lấy mã: [Field] MasterFixedAsset.
*               Lấy tên: Vào [CDS] I_FixedAsset lấy [Field] FixedAssetDescription
          ELSEIF <lfs_data_raw>-masterfixedasset IS NOT INITIAL.
            <lfs_data_raw>-code = <lfs_data_raw>-masterfixedasset.
            <lfs_data_raw>-text = <lfs_data_raw>-fixedassetdescription.
            CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
*            o   Ưu tiên 1.3: Nếu [Field] CostCenter <> null
*               Lấy mã: [Field] CostCenter.
*               Lấy tên: Vào [CDS] I_CostCenterText, Lấy [Field] CostCenterName
          ELSEIF <lfs_data_raw>-costcenter IS NOT INITIAL.
            <lfs_data_raw>-code = <lfs_data_raw>-costcenter.
            <lfs_data_raw>-text = <lfs_data_raw>-costcentername.
            CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
*            o   Ưu tiên 1.4: Nếu [Field] Customer/Supplier <> null.
*            Lấy mã tại [Field] Customer/Supplier.
*            Thứ tự ưu tiên và cách lấy tên tương tự như mục 1.
*            Đối với Customer/Supplier, account type là D/K
          ELSEIF <lfs_data_raw>-customer IS NOT INITIAL.
            READ TABLE lt_customer_name INTO DATA(ls_customer_name)
              WITH KEY customer   = <lfs_data_raw>-customer BINARY SEARCH.
            IF sy-subrc EQ 0.
              <lfs_data_raw>-code = ls_customer_name-customer.
              <lfs_data_raw>-text = ls_customer_name-customerfullname.
              CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
            ENDIF.
          ELSEIF <lfs_data_raw>-supplier IS NOT INITIAL.
            READ TABLE lt_supplier_name INTO DATA(ls_supplier_name)
              WITH KEY supplier   = <lfs_data_raw>-supplier BINARY SEARCH.
            IF sy-subrc EQ 0.
              <lfs_data_raw>-code = ls_supplier_name-supplier.
              <lfs_data_raw>-text = ls_supplier_name-supplierfullname.
              CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
            ENDIF.
*        •   Ưu tiên 2: Lấy đối tượng của tài khoản đối ứng
          ELSE.
            READ TABLE lt_data_raw_all INTO DATA(ls_data_offset)
              WITH KEY companycode          = <lfs_data_raw>-companycode
                       accountingdocument   = <lfs_data_raw>-accountingdocument
                       fiscalyear           = <lfs_data_raw>-fiscalyear
                       glaccount            = <lfs_data_raw>-offsettingaccount BINARY SEARCH.
            IF sy-subrc EQ 0.
*            o   Ưu tiên 2.1: Nếu [Field] Material <> null
*               Lấy mã: [Field] Material.
*               Lấy tên: Vào [CDS] I_ProductText, lấy [Field] ProductName
              IF ls_data_offset-product IS NOT INITIAL.
                <lfs_data_raw>-code = ls_data_offset-product.
                <lfs_data_raw>-text = ls_data_offset-productname.
                CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
*            o   Ưu tiên 2.2: Nếu [Field] MasterFixedAsset <> null
*               Lấy mã: [Field] MasterFixedAsset.
*               Lấy tên: Vào [CDS] I_FixedAsset lấy [Field] FixedAssetDescription.
              ELSEIF ls_data_offset-masterfixedasset IS NOT INITIAL.
                <lfs_data_raw>-code = ls_data_offset-masterfixedasset.
                <lfs_data_raw>-text = ls_data_offset-fixedassetdescription.
                CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
*            o   Ưu tiên 2.3: Nếu [Field] CostCenter <> null
*               Lấy mã: [Field] CostCenter.
*               Lấy tên: Vào [CDS] I_CostCenterText, Lấy [Field] CostCenterName.
              ELSEIF ls_data_offset-costcenter IS NOT INITIAL.
                <lfs_data_raw>-code = ls_data_offset-costcenter.
                <lfs_data_raw>-text = ls_data_offset-costcentername.
                CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
*            o   Ưu tiên 2.4: Nếu [Field] Customer/Supplier <> null.
*            Lấy mã tại [Field] Customer/Supplier.
*            Thứ tự ưu tiên và cách lấy tên tương tự như mục 1. Đối với Customer/Supplier, account type là D/K
              ELSEIF ls_data_offset-customer IS NOT INITIAL.
                READ TABLE lt_customer_name INTO ls_customer_name
                  WITH KEY customer   = ls_data_offset-customer BINARY SEARCH.
                IF sy-subrc EQ 0.
                  <lfs_data_raw>-code = ls_customer_name-customer.
                  <lfs_data_raw>-text = ls_customer_name-customerfullname.
                  CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
                ENDIF.
              ELSEIF ls_data_offset-supplier IS NOT INITIAL.
                READ TABLE lt_supplier_name INTO ls_supplier_name
                  WITH KEY supplier   = ls_data_offset-supplier BINARY SEARCH.
                IF sy-subrc EQ 0.
                  <lfs_data_raw>-code = ls_supplier_name-supplier.
                  <lfs_data_raw>-text = ls_supplier_name-supplierfullname.
                  CONCATENATE <lfs_data_raw>-code <lfs_data_raw>-text INTO <lfs_data_raw>-objecttext SEPARATED BY ` - `.
                ENDIF.
*            •   Ưu tiên 3: Để trống
              ELSE.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

        SHIFT <lfs_data_raw>-objecttext LEFT DELETING LEADING '0'.

        <lfs_data_raw>-creditamountintranscrcy  *= -1.
        <lfs_data_raw>-creditamountincocodecrcy *= -1.

*        IF <lfs_data_raw>-creditamountincocodecrcy = <lfs_data_raw>-debitamountincocodecrcy.
*          CONTINUE.
*        ENDIF.

        IF <lfs_data_raw>-postingdate < lv_fromdate.
          APPEND <lfs_data_raw> TO lt_data_beg.
        ELSE.
          APPEND <lfs_data_raw> TO lt_data_inp.
        ENDIF.
      ENDLOOP.

      SORT lt_data_raw BY glaccount.

      SELECT DISTINCT
        glaccount,
        glaccountlongname
        FROM @lt_data_raw AS data
        INTO TABLE @DATA(lt_glaccount).
      IF sy-subrc EQ 0.
        LOOP AT lt_glaccount INTO DATA(ls_glaccount).
          ls_data-issubtotal = 'X'.
          ls_data-glaccount  = ls_glaccount-glaccount.
          CONCATENATE ls_glaccount-glaccount '-' ls_glaccount-glaccountlongname INTO ls_data-objecttext SEPARATED BY space.
          APPEND ls_data TO et_data.
          CLEAR: ls_data.
          " Số dư đầu kỳ (Opening Balance)
          SELECT
            'X' AS issubtotal,
            1 AS notitle,
            'Số dư đầu kỳ (Opening Balance)' AS objecttext,
            glaccount,
            transactioncurrency,
            companycodecurrency,
            SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
            SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
            SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
            SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
            FROM @lt_data_beg AS data
            WHERE glaccount = @ls_glaccount-glaccount
            GROUP BY
            glaccount,
            transactioncurrency,
            companycodecurrency
            INTO TABLE @DATA(lt_data_beg_subtotal).
          IF sy-subrc NE 0.
            SELECT DISTINCT
              'X' AS issubtotal,
              1 AS notitle,
              'Số dư đầu kỳ (Opening Balance)' AS objecttext,
              glaccount,
              transactioncurrency,
              companycodecurrency
              FROM @lt_data_inp AS data
              WHERE glaccount = @ls_glaccount-glaccount
              INTO CORRESPONDING FIELDS OF TABLE @lt_data_beg_subtotal.
          ENDIF.
          LOOP AT lt_data_beg_subtotal ASSIGNING FIELD-SYMBOL(<lfs_data_beg_subtotal>).
            IF <lfs_data_beg_subtotal>-debitamountintranscrcy - <lfs_data_beg_subtotal>-creditamountintranscrcy < 0.
              <lfs_data_beg_subtotal>-creditamountintranscrcy -= <lfs_data_beg_subtotal>-debitamountintranscrcy.
              <lfs_data_beg_subtotal>-debitamountintranscrcy  = 0.
              <lfs_data_beg_subtotal>-creditamountincocodecrcy -= <lfs_data_beg_subtotal>-debitamountincocodecrcy.
              <lfs_data_beg_subtotal>-debitamountincocodecrcy  = 0.
            ELSE.
              <lfs_data_beg_subtotal>-debitamountintranscrcy -= <lfs_data_beg_subtotal>-creditamountintranscrcy.
              <lfs_data_beg_subtotal>-creditamountintranscrcy = 0.
              <lfs_data_beg_subtotal>-debitamountincocodecrcy -= <lfs_data_beg_subtotal>-creditamountincocodecrcy.
              <lfs_data_beg_subtotal>-creditamountincocodecrcy = 0.
            ENDIF.
          ENDLOOP.

          " Cộng phát sinh (Total Transaction)
          SELECT
            'X' AS issubtotal,
            2 AS notitle,
            'Cộng phát sinh (Total Transaction)' AS objecttext,
            glaccount,
            transactioncurrency,
            companycodecurrency,
            SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
            SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
            SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
            SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
            FROM @lt_data_inp AS data
            WHERE glaccount = @ls_glaccount-glaccount
            GROUP BY
            glaccount,
            transactioncurrency,
            companycodecurrency
            INTO TABLE @DATA(lt_data_inp_subtotal).
          IF sy-subrc NE 0.
            SELECT DISTINCT
              'X' AS issubtotal,
              2 AS notitle,
              'Cộng phát sinh (Total Transaction)' AS objecttext,
              glaccount,
              transactioncurrency,
              companycodecurrency
              FROM @lt_data_beg AS data
              WHERE glaccount = @ls_glaccount-glaccount
              INTO CORRESPONDING FIELDS OF TABLE @lt_data_inp_subtotal.
          ENDIF.

          " Số dư cuối kỳ (Closing Balance)
          SELECT
            'X' AS issubtotal,
            3 AS notitle,
            'Số dư cuối kỳ (Closing Balance)' AS objecttext,
            glaccount,
            transactioncurrency,
            companycodecurrency,
            SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
            SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
            SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
            SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
            FROM @lt_data_raw AS data
            WHERE glaccount = @ls_glaccount-glaccount
            GROUP BY
            glaccount,
            transactioncurrency,
            companycodecurrency
            INTO TABLE @DATA(lt_data_raw_subtotal).

          LOOP AT lt_data_raw_subtotal ASSIGNING FIELD-SYMBOL(<lfs_data_raw_subtotal>).
            IF <lfs_data_raw_subtotal>-debitamountintranscrcy - <lfs_data_raw_subtotal>-creditamountintranscrcy < 0.
              <lfs_data_raw_subtotal>-creditamountintranscrcy -= <lfs_data_raw_subtotal>-debitamountintranscrcy.
              <lfs_data_raw_subtotal>-debitamountintranscrcy  = 0.
              <lfs_data_raw_subtotal>-creditamountincocodecrcy -= <lfs_data_raw_subtotal>-debitamountincocodecrcy.
              <lfs_data_raw_subtotal>-debitamountincocodecrcy  = 0.
            ELSE.
              <lfs_data_raw_subtotal>-debitamountintranscrcy -= <lfs_data_raw_subtotal>-creditamountintranscrcy.
              <lfs_data_raw_subtotal>-creditamountintranscrcy = 0.
              <lfs_data_raw_subtotal>-debitamountincocodecrcy -= <lfs_data_raw_subtotal>-creditamountincocodecrcy.
              <lfs_data_raw_subtotal>-creditamountincocodecrcy = 0.
            ENDIF.
          ENDLOOP.

          MOVE-CORRESPONDING lt_data_beg_subtotal TO lt_data.
          APPEND LINES OF lt_data TO et_data.
          APPEND LINES OF lt_data TO lt_data_sum_beg.
          MOVE-CORRESPONDING lt_data_inp_subtotal TO lt_data.
          APPEND LINES OF lt_data TO et_data.
          APPEND LINES OF lt_data TO lt_data_sum_inp.
          MOVE-CORRESPONDING lt_data_raw_subtotal TO lt_data.
          APPEND LINES OF lt_data TO et_data.
          APPEND LINES OF lt_data TO lt_data_sum_end.
        ENDLOOP.
      ENDIF.

      " Tổng số dư đầu kỳ (Opening Balance)
      SELECT
        'X' AS istotal,
        1 AS notitle,
        'Tổng số dư đầu kỳ (Opening Balance)' AS objecttext,
        transactioncurrency,
        companycodecurrency,
        SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
        SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
        SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
        SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
        FROM @lt_data_sum_beg AS data
        GROUP BY
        transactioncurrency,
        companycodecurrency
        INTO TABLE @DATA(lt_data_beg_total).
      IF sy-subrc NE 0.
        SELECT DISTINCT
          'X' AS istotal,
          1 AS notitle,
          'Tổng số dư đầu kỳ (Opening Balance)' AS objecttext,
          transactioncurrency,
          companycodecurrency
          FROM @lt_data_sum_inp AS data
          INTO CORRESPONDING FIELDS OF TABLE @lt_data_beg_total.
      ELSE.
        LOOP AT lt_data_beg_total ASSIGNING FIELD-SYMBOL(<lfs_data_beg_total>).
          IF <lfs_data_beg_total>-debitamountintranscrcy > <lfs_data_beg_total>-creditamountintranscrcy.
            <lfs_data_beg_total>-debitamountintranscrcy -= <lfs_data_beg_total>-creditamountintranscrcy.
            <lfs_data_beg_total>-creditamountintranscrcy = 0.
            <lfs_data_beg_total>-debitamountincocodecrcy -= <lfs_data_beg_total>-creditamountincocodecrcy.
            <lfs_data_beg_total>-creditamountincocodecrcy = 0.
          ELSE.
            <lfs_data_beg_total>-creditamountintranscrcy -= <lfs_data_beg_total>-debitamountintranscrcy.
            <lfs_data_beg_total>-debitamountintranscrcy   = 0.
            <lfs_data_beg_total>-creditamountincocodecrcy -= <lfs_data_beg_total>-debitamountincocodecrcy.
            <lfs_data_beg_total>-debitamountincocodecrcy   = 0.
          ENDIF.
        ENDLOOP.
      ENDIF.

      " Tổng cộng phát sinh (Total Transaction)
      SELECT
        'X' AS istotal,
        2 AS notitle,
        'Tổng cộng phát sinh (Total Transaction)' AS objecttext,
        transactioncurrency,
        companycodecurrency,
        SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
        SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
        SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
        SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
        FROM @lt_data_sum_inp AS data
        GROUP BY
        transactioncurrency,
        companycodecurrency
        INTO TABLE @DATA(lt_data_inp_total).
      IF sy-subrc NE 0.
        SELECT DISTINCT
          'X' AS istotal,
          2 AS notitle,
          'Tổng cộng phát sinh (Total Transaction)' AS objecttext,
          transactioncurrency,
          companycodecurrency
          FROM @lt_data_sum_beg AS data
          INTO CORRESPONDING FIELDS OF TABLE @lt_data_inp_total.
      ENDIF.

      " Tổng số dư cuối kỳ (Closing Balance)
      SELECT
        'X' AS istotal,
        3 AS notitle,
        'Tổng số dư cuối kỳ (Closing Balance)' AS objecttext,
        transactioncurrency,
        companycodecurrency,
        SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
        SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
        SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
        SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
        FROM @lt_data_sum_end AS data
        GROUP BY
        transactioncurrency,
        companycodecurrency
        INTO TABLE @DATA(lt_data_raw_total).
      IF sy-subrc EQ 0.
        LOOP AT lt_data_raw_total ASSIGNING FIELD-SYMBOL(<lfs_data_raw_total>).
          IF <lfs_data_raw_total>-debitamountintranscrcy > <lfs_data_raw_total>-creditamountintranscrcy.
            <lfs_data_raw_total>-debitamountintranscrcy -= <lfs_data_raw_total>-creditamountintranscrcy.
            <lfs_data_raw_total>-creditamountintranscrcy = 0.
            <lfs_data_raw_total>-debitamountincocodecrcy -= <lfs_data_raw_total>-creditamountincocodecrcy.
            <lfs_data_raw_total>-creditamountincocodecrcy = 0.
          ELSE.
            <lfs_data_raw_total>-creditamountintranscrcy -= <lfs_data_raw_total>-debitamountintranscrcy.
            <lfs_data_raw_total>-debitamountintranscrcy   = 0.
            <lfs_data_raw_total>-creditamountincocodecrcy -= <lfs_data_raw_total>-debitamountincocodecrcy.
            <lfs_data_raw_total>-debitamountincocodecrcy   = 0.
          ENDIF.
        ENDLOOP.
      ENDIF.

      MOVE-CORRESPONDING lt_data_beg_total TO lt_data.
      APPEND LINES OF lt_data TO et_data.
      MOVE-CORRESPONDING lt_data_inp_total TO lt_data.
      APPEND LINES OF lt_data TO et_data.
      MOVE-CORRESPONDING lt_data_raw_total TO lt_data.
      APPEND LINES OF lt_data TO et_data.

      APPEND LINES OF lt_data_inp TO et_data.

      mt_data        = et_data.
      mt_parameter   = lt_paramater.
      mt_filter_cond = lt_filter_cond.
    ENDIF.
  ENDMETHOD.


  METHOD get_instance.
    IF go_instance IS INITIAL.
      CREATE OBJECT go_instance.
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.
ENDCLASS.
