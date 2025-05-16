@EndUserText.label: 'Sổ chi tiết tài khoản'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_FI_SCTTK'
@UI: {
    headerInfo: {
        typeName: 'Sổ chi tiết tài khoản',
        typeNamePlural: 'Sổ chi tiết tài khoản',
        title: {
            type: #STANDARD,
            label: 'Sổ chi tiết tài khoản'
        }
    }
}
define custom entity ZI_FI_SCTTK
  with parameters
    @Consumption:{
    valueHelpDefinition: [{ entity: {
    name: 'ZI_LedgerVH',
    element: 'Ledger'
    } }]
    }
    @EndUserText.label: 'Ledger'
    P_Ledger       : fins_ledger,
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_YES_NO_VH',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Include Reversed Documents'
    P_IncRev       : zde_yes_no,
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_YES_NO_VH',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Tổng cộng theo tài khoản'
    P_FlagSum      : zde_yes_no,
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_YES_NO_VH',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Ngày giờ in'
    P_PrintDate    : zde_yes_no,
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_CURR_TYPE',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Loại mẫu báo cáo'
    P_CurrencyType : zde_curr_type
{
      @Consumption.valueHelpDefinition: [ {
         entity                :{
         name                  :'I_CurrencyStdVH',
         element               :'Currency' }
         }]
      @UI                      : {
      selectionField           : [ { position: 01 } ] }
      @EndUserText.label       : 'Currency'
  key TransactionCurrency      : waers; 
      @Consumption             : {
      valueHelpDefinition      : [ {
      entity                   :{
      name                     :'I_CompanyCodeStdVH',
      element                  :'CompanyCode' }
      }],
      filter                   :{ mandatory:true } }
      @UI                      : {
      selectionField           : [ { position: 10 } ] }
      @EndUserText.label       : 'CompanyCode'
  key CompanyCode              : bukrs;
  key AccountingDocument       : belnr_d;
  key LedgerGLLineItem         : abap.char(6);
      @Consumption             :{filter    : {
      mandatory                :false
      },
      valueHelpDefinition      : [ { entity :
      {
      name                     :'I_GLAccountStdVH',
      element                  :'GLAccount' }
      } ]
      }
      @UI                      : {
      selectionField           : [ { position: 50 } ] }
      @EndUserText.label       : 'G/L Accounts'
  key GLAccount                : zde_racct;
      @Consumption.filter      : {
      selectionType            : #SINGLE,
      mandatory                :true
      }
      @UI                      : {
      selectionField           : [ { position: 20 } ] }
      @EndUserText.label       : 'Fiscal Year'
  key FiscalYear               : fis_gjahr_no_conv;
  key IsTotal                  : abap.char(1);
  key IsSubTotal               : abap.char(1);
  key NoTitle                  : abap.numc(1);
      @Consumption             :{
      valueHelpDefinition      : [ { entity :
      {
      name                     :'I_GLAccountStdVH',
      element                  :'GLAccount' }
      } ]
      }
      @UI                      : {
      selectionField           : [ { position: 60 } ] }
      @EndUserText.label       : 'Offsetting Account'
      OffsettingAccount        : zde_racct;
      GLAccountLongName        : abap.char(50);
      @Consumption.filter      : {
      selectionType            : #INTERVAL
      }
      @UI                      : {
      selectionField           : [ { position: 30 } ] } 
      @EndUserText.label       : 'Period'
      @UI.hidden: true
      FiscalPeriod             : fins_fiscalperiod;
      @Consumption.filter      : {
      selectionType            : #INTERVAL,
      mandatory                :true
      }
      @UI                      : {
      selectionField           : [ { position: 40 } ] }
      @EndUserText.label       : 'Posting Date'
      PostingDate              : fis_budat;
      DocumentDate             : bldat;
      CompanyCodeCurrency      : waers;
      FinancialAccountType     : koart;
      Code                     : abap.char(20);
      Text                     : abap.char(100);
      ObjectText               : abap.char(200);
      DienGiai                 : abap.char(100);
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      DebitAmountInTransCrcy   : abap.curr(23, 2);
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      DebitAmountInCoCodeCrcy  : abap.curr(23, 2);
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      CreditAmountInTransCrcy  : abap.curr(23, 2);
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      CreditAmountInCoCodeCrcy : abap.curr(23, 2);  
      Product                  : matnr;
      ProductName              : maktx;
      MasterFixedAsset         : anln1;
      FixedAsset               : anln2;
      FixedAssetDescription    : abap.char(50);
      CostCenter               : kostl;
      CostCenterName           : ktext; 
      Customer                 : kunnr;
      Supplier                 : lifnr;
      AssignmentReference      : dzuonr;
}
