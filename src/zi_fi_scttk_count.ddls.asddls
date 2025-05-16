@EndUserText.label: 'Sổ chi tiết tài khoản - Count'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_FI_SCTTK'
define custom entity ZI_FI_SCTTK_COUNT
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
  key CountTotalRecord    : abap.int4;
      TransactionCurrency : waers;
      CompanyCode         : bukrs;
      GLAccount           : zde_racct;
      FiscalYear          : fis_gjahr_no_conv;
      OffsettingAccount   : zde_racct; 
      FiscalPeriod        : fins_fiscalperiod;
      PostingDate         : fis_budat;
}
