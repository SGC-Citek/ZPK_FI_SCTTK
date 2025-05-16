@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sổ chi tiết tài khoản - SUM'
define view entity ZI_FI_SCTTK_SUM
  with parameters
    P_Ledger       : fins_ledger,
    P_IncRev       : zde_boolean,
    P_CurrencyType : zde_curr_type,
    P_FlagSum      : zde_boolean
    
  as select from    ZI_FI_SCTTK_RAW (   P_Ledger        : $parameters.P_Ledger,
                                        P_IncRev        : $parameters.P_IncRev,
                                        P_CurrencyType  : $parameters.P_CurrencyType,
                                        P_FlagSum       : $parameters.P_FlagSum ) as data
    left outer join I_GlAccountTextInCompanycode                                  as text on  data.GLAccount   = text.GLAccount
                                                                                          and data.CompanyCode = text.CompanyCode
                                                                                          and text.Language    = $session.system_language
    left outer join I_ProductText                                                         on  I_ProductText.Product  = data.Product
                                                                                          and I_ProductText.Language = $session.system_language
    left outer join I_FixedAsset                                                          on  I_FixedAsset.MasterFixedAsset = data.MasterFixedAsset
                                                                                          and I_FixedAsset.FixedAsset       = data.FixedAsset
                                                                                          and I_FixedAsset.CompanyCode      = data.CompanyCode
    left outer join I_CostCenterText                                                      on  I_CostCenterText.CostCenter      = data.CostCenter
                                                                                          and I_CostCenterText.ControllingArea = data.ControllingArea
                                                                                          and I_CostCenterText.Language        = $session.system_language
                                                                                          and I_CostCenterText.ValidityEndDate >= $session.system_date
{
  key data.CompanyCode,
  key data.AccountingDocument,
  key data.LedgerGLLineItem,
  key data.FiscalYear,
      data.AssignmentReference,
      data.FiscalPeriod,
      data.PostingDate,
      data.DocumentDate,
      data.GLAccount,
      text.GLAccountLongName,
      data.OffsettingAccount,
      data.TransactionCurrency,
      data.CompanyCodeCurrency,
      data.FinancialAccountType,
      data.Code,
      data.Text,
      data.DienGiai,
      data.Product,
      I_ProductText.ProductName,
      data.MasterFixedAsset,
      data.FixedAsset,
      I_FixedAsset.FixedAssetDescription,
      data.CostCenter,
      I_CostCenterText.CostCenterName,
      data.Customer,
      data.Supplier,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( data.DebitAmountInTransCrcy )   as DebitAmountInTransCrcy,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      sum( data.DebitAmountInCoCodeCrcy )  as DebitAmountInCoCodeCrcy,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( data.CreditAmountInTransCrcy )  as CreditAmountInTransCrcy,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      sum( data.CreditAmountInCoCodeCrcy ) as CreditAmountInCoCodeCrcy
}
group by
  data.CompanyCode,
  data.AccountingDocument,
  data.LedgerGLLineItem,
  data.FiscalYear,
  data.AssignmentReference,
  data.FiscalPeriod,
  data.PostingDate,
  data.DocumentDate,
  data.GLAccount,
  text.GLAccountLongName,
  data.OffsettingAccount,
  data.TransactionCurrency,
  data.CompanyCodeCurrency,
  data.FinancialAccountType,
  data.Code,
  data.Text,
  data.DienGiai,
  data.Product,
  I_ProductText.ProductName,
  data.MasterFixedAsset,
  data.FixedAsset,
  I_FixedAsset.FixedAssetDescription,
  data.CostCenter,
  I_CostCenterText.CostCenterName,
  data.Customer,
  data.Supplier
