@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sổ chi tiết tài khoản - RAW'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_FI_SCTTK_RAW
  with parameters
    P_Ledger       : fins_ledger,
    P_IncRev       : zde_boolean,
    P_CurrencyType : zde_curr_type,
    P_FlagSum      : zde_boolean
  as select from    I_GLAccountLineItem
    inner join      I_GLAccountLineItem      as OffsettingLine on  I_GLAccountLineItem.SourceLedger       = OffsettingLine.SourceLedger
                                                               and I_GLAccountLineItem.CompanyCode        = OffsettingLine.CompanyCode
                                                               and I_GLAccountLineItem.FiscalYear         = OffsettingLine.FiscalYear
                                                               and I_GLAccountLineItem.AccountingDocument = OffsettingLine.AccountingDocument
                                                               and I_GLAccountLineItem.LedgerGLLineItem   = OffsettingLine.OffsettingLedgerGLLineItem
                                                               and I_GLAccountLineItem.Ledger             = OffsettingLine.Ledger
    left outer join I_OperationalAcctgDocItem                  on  I_GLAccountLineItem.CompanyCode            = I_OperationalAcctgDocItem.CompanyCode
                                                               and I_GLAccountLineItem.FiscalYear             = I_OperationalAcctgDocItem.FiscalYear
                                                               and I_GLAccountLineItem.AccountingDocument     = I_OperationalAcctgDocItem.AccountingDocument
                                                               and I_GLAccountLineItem.AccountingDocumentItem = I_OperationalAcctgDocItem.AccountingDocumentItem
    left outer join I_JournalEntry                             on  I_OperationalAcctgDocItem.CompanyCode        = I_JournalEntry.CompanyCode
                                                               and I_OperationalAcctgDocItem.FiscalYear         = I_JournalEntry.FiscalYear
                                                               and I_OperationalAcctgDocItem.AccountingDocument = I_JournalEntry.AccountingDocument
    left outer join ZCORE_I_PROFILE_FIDOC_V2 as ProfileFI      on  I_GLAccountLineItem.AccountingDocument     = ProfileFI.AccountingDocument
                                                               and I_GLAccountLineItem.AccountingDocumentItem = ProfileFI.AccountingDocumentItem
                                                               and I_GLAccountLineItem.LedgerGLLineItem       = ProfileFI.LedgerGLLineItem
                                                               and I_GLAccountLineItem.FiscalYear             = ProfileFI.FiscalYear
                                                               and I_GLAccountLineItem.CompanyCode            = ProfileFI.CompanyCode
                                                               and ProfileFI.Account                          is not initial
                                                               and ProfileFI.AccountnName                     is not initial
  //    left outer join ZCORE_I_PROFILE_FIDOC_V2 as ProfileFIOff   on  OffsettingLine.AccountingDocument     = ProfileFIOff.AccountingDocument
  //                                                               and OffsettingLine.AccountingDocumentItem = ProfileFIOff.AccountingDocumentItem
  //                                                               and OffsettingLine.FiscalYear             = ProfileFIOff.FiscalYear
  //                                                               and OffsettingLine.CompanyCode            = ProfileFIOff.CompanyCode
  //      left outer join ZCORE_I_PROFILE_FIDOC as ProfileFIObj   on  ProfileFIObj.AccountingDocument   =  I_GLAccountLineItem.AccountingDocument
  //                                                              and ProfileFIObj.FinancialAccountType <> 'S'
  //                                                              and ProfileFIObj.FiscalYear           =  I_GLAccountLineItem.FiscalYear
  //                                                              and ProfileFIObj.CompanyCode          =  I_GLAccountLineItem.CompanyCode
{
  key I_GLAccountLineItem.CompanyCode,
  key I_GLAccountLineItem.AccountingDocument,
  key I_GLAccountLineItem.LedgerGLLineItem as LedgerGLLineItemRaw,
  key I_GLAccountLineItem.FiscalYear,
      I_GLAccountLineItem.AssignmentReference,
      case when $parameters.P_FlagSum = 'N'
            then I_GLAccountLineItem.LedgerGLLineItem
            else '000000'
          end                              as LedgerGLLineItem,
      I_GLAccountLineItem.FiscalPeriod,
      I_GLAccountLineItem.PostingDate,
      I_GLAccountLineItem.DocumentDate,
      I_GLAccountLineItem.GLAccount,
      OffsettingLine.GLAccount             as OffsettingAccount,
      //Khai.Truong
      case when $parameters.P_CurrencyType = 'T'
            then I_GLAccountLineItem.CompanyCodeCurrency
            else I_GLAccountLineItem.TransactionCurrency
      end                                  as TransactionCurrency,

      //      I_GLAccountLineItem.TransactionCurrency,

      I_GLAccountLineItem.CompanyCodeCurrency,
      I_GLAccountLineItem.FinancialAccountType,
      //      I_OperationalAcctgDocItem.FinancialAccountType,
      //      case when I_OperationalAcctgDocItem.FinancialAccountType = 'S' and ProfileFIOff.Account is not initial
      //            then ProfileFIOff.Account
      //           when I_OperationalAcctgDocItem.FinancialAccountType = 'S'
      //            then ' '
      //            else ProfileFI.Account
      //      end                                  as Code,
      ProfileFI.Account                    as Code,
      //      case when I_OperationalAcctgDocItem.FinancialAccountType = 'S' and ProfileFIOff.Account is not initial
      //            then ProfileFIOff.AccountnName
      //           when I_OperationalAcctgDocItem.FinancialAccountType = 'S'
      //            then ' '
      //            else ProfileFI.AccountnName
      //      end                                  as Text,
      ProfileFI.AccountnName               as Text,
      case
        when I_GLAccountLineItem.DocumentItemText != ''
        then I_GLAccountLineItem.DocumentItemText
        else  I_JournalEntry.AccountingDocumentHeaderText
      end                                  as DienGiai,


      ////Khai.Truong
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when $parameters.P_CurrencyType = 'T'
            then I_GLAccountLineItem.DebitAmountInCoCodeCrcy
            else I_GLAccountLineItem.DebitAmountInTransCrcy
      end                                  as DebitAmountInTransCrcy,

      //       @Semantics.amount.currencyCode: 'TransactionCurrency'
      //       I_GLAccountLineItem.DebitAmountInTransCrcy,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      I_GLAccountLineItem.DebitAmountInCoCodeCrcy,

      //////Khai.Truong
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when $parameters.P_CurrencyType = 'T'
            then I_GLAccountLineItem.CreditAmountInCoCodeCrcy
            else I_GLAccountLineItem.CreditAmountInTransCrcy
      end                                  as CreditAmountInTransCrcy,

      //      @Semantics.amount.currencyCode: 'TransactionCurrency'
      //      I_GLAccountLineItem.CreditAmountInTransCrcy,


      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      I_GLAccountLineItem.CreditAmountInCoCodeCrcy,
      I_GLAccountLineItem.ControllingArea,
      I_GLAccountLineItem.Product,
      I_GLAccountLineItem.CostCenter,
      I_GLAccountLineItem.MasterFixedAsset,
      I_GLAccountLineItem.FixedAsset,
      I_GLAccountLineItem.Customer,
      I_GLAccountLineItem.Supplier
}
where
          I_GLAccountLineItem.Ledger              = $parameters.P_Ledger
  and     I_GLAccountLineItem.SourceLedger        = $parameters.P_Ledger
  and(
    (
          $parameters.P_IncRev                    =  'Y'
    )
    or(
          $parameters.P_IncRev                    =  'N'
      and I_GLAccountLineItem.IsReversal          is initial
      and I_GLAccountLineItem.IsReversed          is initial
    )
  )
  and(
    (
          $parameters.P_CurrencyType              =  'I'
      and I_GLAccountLineItem.TransactionCurrency =  'VND'
    )
    or(
          $parameters.P_CurrencyType              =  'E'
      and I_GLAccountLineItem.TransactionCurrency <> I_GLAccountLineItem.CompanyCodeCurrency
    )
    or(
          $parameters.P_CurrencyType              =  'T'
      and I_GLAccountLineItem.CompanyCodeCurrency =  'VND'
    )
  )
//union select from I_GLAccountLineItem
//  inner join      I_GLAccountLineItem      as OffsettingLine on  I_GLAccountLineItem.SourceLedger               = OffsettingLine.SourceLedger
//                                                             and I_GLAccountLineItem.CompanyCode                = OffsettingLine.CompanyCode
//                                                             and I_GLAccountLineItem.FiscalYear                 = OffsettingLine.FiscalYear
//                                                             and I_GLAccountLineItem.AccountingDocument         = OffsettingLine.AccountingDocument
//                                                             and I_GLAccountLineItem.OffsettingLedgerGLLineItem = OffsettingLine.LedgerGLLineItem
//                                                             and I_GLAccountLineItem.Ledger                     = OffsettingLine.Ledger
//  left outer join I_OperationalAcctgDocItem                  on  I_GLAccountLineItem.CompanyCode            = I_OperationalAcctgDocItem.CompanyCode
//                                                             and I_GLAccountLineItem.FiscalYear             = I_OperationalAcctgDocItem.FiscalYear
//                                                             and I_GLAccountLineItem.AccountingDocument     = I_OperationalAcctgDocItem.AccountingDocument
//                                                             and I_GLAccountLineItem.AccountingDocumentItem = I_OperationalAcctgDocItem.AccountingDocumentItem
//  left outer join I_JournalEntry                             on  I_OperationalAcctgDocItem.CompanyCode        = I_JournalEntry.CompanyCode
//                                                             and I_OperationalAcctgDocItem.FiscalYear         = I_JournalEntry.FiscalYear
//                                                             and I_OperationalAcctgDocItem.AccountingDocument = I_JournalEntry.AccountingDocument
//  left outer join ZCORE_I_PROFILE_FIDOC_V2 as ProfileFI      on  I_GLAccountLineItem.AccountingDocument     = ProfileFI.AccountingDocument
//                                                             and I_GLAccountLineItem.AccountingDocumentItem = ProfileFI.AccountingDocumentItem
//                                                             and I_GLAccountLineItem.LedgerGLLineItem       = ProfileFI.LedgerGLLineItem
//                                                             and I_GLAccountLineItem.FiscalYear             = ProfileFI.FiscalYear
//                                                             and I_GLAccountLineItem.CompanyCode            = ProfileFI.CompanyCode
//                                                             and ProfileFI.Account                          is not initial
//                                                             and ProfileFI.AccountnName                     is not initial
////    left outer join ZCORE_I_PROFILE_FIDOC_V2 as ProfileFIOff   on  OffsettingLine.AccountingDocument     = ProfileFIOff.AccountingDocument
////                                                               and OffsettingLine.AccountingDocumentItem = ProfileFIOff.AccountingDocumentItem
////                                                               and OffsettingLine.FiscalYear             = ProfileFIOff.FiscalYear
////                                                               and OffsettingLine.CompanyCode            = ProfileFIOff.CompanyCode
////      left outer join ZCORE_I_PROFILE_FIDOC as ProfileFIObj   on  ProfileFIObj.AccountingDocument   =  I_GLAccountLineItem.AccountingDocument
////                                                              and ProfileFIObj.FinancialAccountType <> 'S'
////                                                              and ProfileFIObj.FiscalYear           =  I_GLAccountLineItem.FiscalYear
////                                                              and ProfileFIObj.CompanyCode          =  I_GLAccountLineItem.CompanyCode
//{
//  key I_GLAccountLineItem.CompanyCode,
//  key I_GLAccountLineItem.AccountingDocument,
//  key I_GLAccountLineItem.LedgerGLLineItem as LedgerGLLineItemRaw,
//  key I_GLAccountLineItem.FiscalYear,
//      I_GLAccountLineItem.AssignmentReference,
//      case when $parameters.P_FlagSum = 'N'
//            then I_GLAccountLineItem.LedgerGLLineItem
//            else '000000'
//          end                              as LedgerGLLineItem,
//      I_GLAccountLineItem.FiscalPeriod,
//      I_GLAccountLineItem.PostingDate,
//      I_GLAccountLineItem.DocumentDate,
//      I_GLAccountLineItem.GLAccount,
//      OffsettingLine.GLAccount             as OffsettingAccount,
//      //Khai.Truong
//      case when $parameters.P_CurrencyType = 'T'
//            then I_GLAccountLineItem.CompanyCodeCurrency
//            else I_GLAccountLineItem.TransactionCurrency
//      end                                  as TransactionCurrency,
//
//      //      I_GLAccountLineItem.TransactionCurrency,
//
//      I_GLAccountLineItem.CompanyCodeCurrency,
//      I_GLAccountLineItem.FinancialAccountType,
//      //      I_OperationalAcctgDocItem.FinancialAccountType,
//      //      case when I_OperationalAcctgDocItem.FinancialAccountType = 'S' and ProfileFIOff.Account is not initial
//      //            then ProfileFIOff.Account
//      //           when I_OperationalAcctgDocItem.FinancialAccountType = 'S'
//      //            then ' '
//      //            else ProfileFI.Account
//      //      end                                  as Code,
//      ProfileFI.Account                    as Code,
//      //      case when I_OperationalAcctgDocItem.FinancialAccountType = 'S' and ProfileFIOff.Account is not initial
//      //            then ProfileFIOff.AccountnName
//      //           when I_OperationalAcctgDocItem.FinancialAccountType = 'S'
//      //            then ' '
//      //            else ProfileFI.AccountnName
//      //      end                                  as Text,
//      ProfileFI.AccountnName               as Text,
//      case
//        when I_GLAccountLineItem.DocumentItemText != ''
//        then I_GLAccountLineItem.DocumentItemText
//        else  I_JournalEntry.AccountingDocumentHeaderText
//      end                                  as DienGiai,
//
//
//      ////Khai.Truong
//      case when $parameters.P_CurrencyType = 'T'
//            then I_GLAccountLineItem.DebitAmountInCoCodeCrcy
//            else I_GLAccountLineItem.DebitAmountInTransCrcy
//      end                                  as DebitAmountInTransCrcy,
//
//      //       @Semantics.amount.currencyCode: 'TransactionCurrency'
//      //       I_GLAccountLineItem.DebitAmountInTransCrcy,
//
//      I_GLAccountLineItem.DebitAmountInCoCodeCrcy,
//
//      case when $parameters.P_CurrencyType = 'T'
//            then I_GLAccountLineItem.CreditAmountInCoCodeCrcy
//            else I_GLAccountLineItem.CreditAmountInTransCrcy
//      end                                  as CreditAmountInTransCrcy,
//
//      //      @Semantics.amount.currencyCode: 'TransactionCurrency'
//      //      I_GLAccountLineItem.CreditAmountInTransCrcy,
//
//
//      I_GLAccountLineItem.CreditAmountInCoCodeCrcy,
//      I_GLAccountLineItem.ControllingArea,
//      I_GLAccountLineItem.Product,
//      I_GLAccountLineItem.CostCenter,
//      I_GLAccountLineItem.MasterFixedAsset,
//      I_GLAccountLineItem.FixedAsset,
//      I_GLAccountLineItem.Customer,
//      I_GLAccountLineItem.Supplier
//}
//where
//          I_GLAccountLineItem.Ledger              = $parameters.P_Ledger
//  and     I_GLAccountLineItem.SourceLedger        = $parameters.P_Ledger
//  and(
//    (
//          $parameters.P_IncRev                    =  'Y'
//    )
//    or(
//          $parameters.P_IncRev                    =  'N'
//      and I_GLAccountLineItem.IsReversal          is initial
//      and I_GLAccountLineItem.IsReversed          is initial
//    )
//  )
//  and(
//    (
//          $parameters.P_CurrencyType              =  'I'
//      and I_GLAccountLineItem.TransactionCurrency =  'VND'
//    )
//    or(
//          $parameters.P_CurrencyType              =  'E'
//      and I_GLAccountLineItem.TransactionCurrency <> I_GLAccountLineItem.CompanyCodeCurrency
//    )
//    or(
//          $parameters.P_CurrencyType              =  'T'
//      and I_GLAccountLineItem.CompanyCodeCurrency =  'VND'
//    )
//  )
//union select from I_GLAccountLineItem
//  inner join      I_GLAccountLineItem      as OffsettingLine on  I_GLAccountLineItem.SourceLedger       = OffsettingLine.SourceLedger
//                                                             and I_GLAccountLineItem.CompanyCode        = OffsettingLine.CompanyCode
//                                                             and I_GLAccountLineItem.FiscalYear         = OffsettingLine.FiscalYear
//                                                             and I_GLAccountLineItem.AccountingDocument = OffsettingLine.AccountingDocument
//                                                             and I_GLAccountLineItem.LedgerGLLineItem   = OffsettingLine.OffsettingAccount
//  //                                                               and I_GLAccountLineItem.GLAccount          = OffsettingLine.OffsettingAccount
//                                                             and I_GLAccountLineItem.Ledger             = OffsettingLine.Ledger
//  left outer join I_OperationalAcctgDocItem                  on  I_GLAccountLineItem.CompanyCode            = I_OperationalAcctgDocItem.CompanyCode
//                                                             and I_GLAccountLineItem.FiscalYear             = I_OperationalAcctgDocItem.FiscalYear
//                                                             and I_GLAccountLineItem.AccountingDocument     = I_OperationalAcctgDocItem.AccountingDocument
//                                                             and I_GLAccountLineItem.AccountingDocumentItem = I_OperationalAcctgDocItem.AccountingDocumentItem
//  left outer join I_JournalEntry                             on  I_OperationalAcctgDocItem.CompanyCode        = I_JournalEntry.CompanyCode
//                                                             and I_OperationalAcctgDocItem.FiscalYear         = I_JournalEntry.FiscalYear
//                                                             and I_OperationalAcctgDocItem.AccountingDocument = I_JournalEntry.AccountingDocument
//  left outer join ZCORE_I_PROFILE_FIDOC_V2 as ProfileFI      on  I_GLAccountLineItem.AccountingDocument     = ProfileFI.AccountingDocument
//                                                             and I_GLAccountLineItem.AccountingDocumentItem = ProfileFI.AccountingDocumentItem
//                                                             and I_GLAccountLineItem.LedgerGLLineItem       = ProfileFI.LedgerGLLineItem
//                                                             and I_GLAccountLineItem.FiscalYear             = ProfileFI.FiscalYear
//                                                             and I_GLAccountLineItem.CompanyCode            = ProfileFI.CompanyCode
//                                                             and ProfileFI.Account                          is not initial
//                                                             and ProfileFI.AccountnName                     is not initial
////    left outer join ZCORE_I_PROFILE_FIDOC_V2 as ProfileFIOff   on  OffsettingLine.AccountingDocument     = ProfileFIOff.AccountingDocument
////                                                               and OffsettingLine.AccountingDocumentItem = ProfileFIOff.AccountingDocumentItem
////                                                               and OffsettingLine.FiscalYear             = ProfileFIOff.FiscalYear
////                                                               and OffsettingLine.CompanyCode            = ProfileFIOff.CompanyCode
////      left outer join ZCORE_I_PROFILE_FIDOC as ProfileFIObj   on  ProfileFIObj.AccountingDocument   =  I_GLAccountLineItem.AccountingDocument
////                                                              and ProfileFIObj.FinancialAccountType <> 'S'
////                                                              and ProfileFIObj.FiscalYear           =  I_GLAccountLineItem.FiscalYear
////                                                              and ProfileFIObj.CompanyCode          =  I_GLAccountLineItem.CompanyCode
//{
//  key I_GLAccountLineItem.CompanyCode,
//  key I_GLAccountLineItem.AccountingDocument,
//  key I_GLAccountLineItem.LedgerGLLineItem as LedgerGLLineItemRaw,
//  key I_GLAccountLineItem.FiscalYear,
//      I_GLAccountLineItem.AssignmentReference,
//      case when $parameters.P_FlagSum = 'N'
//            then I_GLAccountLineItem.LedgerGLLineItem
//            else '000000'
//          end                              as LedgerGLLineItem,
//      I_GLAccountLineItem.FiscalPeriod,
//      I_GLAccountLineItem.PostingDate,
//      I_GLAccountLineItem.DocumentDate,
//      I_GLAccountLineItem.GLAccount,
//      OffsettingLine.GLAccount             as OffsettingAccount,
//
//      //////Khai.Truong
//      case when $parameters.P_CurrencyType = 'T'
//            then I_GLAccountLineItem.CompanyCodeCurrency
//            else I_GLAccountLineItem.TransactionCurrency
//      end                                  as TransactionCurrency,
//
//      //      I_GLAccountLineItem.TransactionCurrency,
//
//      I_GLAccountLineItem.CompanyCodeCurrency,
//      I_GLAccountLineItem.FinancialAccountType,
//      //      I_OperationalAcctgDocItem.FinancialAccountType,
//      //      case when I_OperationalAcctgDocItem.FinancialAccountType = 'S' and ProfileFIOff.Account is not initial
//      //            then ProfileFIOff.Account
//      //           when I_OperationalAcctgDocItem.FinancialAccountType = 'S'
//      //            then ' '
//      //            else ProfileFI.Account
//      //      end                                  as Code,
//      ProfileFI.Account                    as Code,
//      //      case when I_OperationalAcctgDocItem.FinancialAccountType = 'S' and ProfileFIOff.Account is not initial
//      //            then ProfileFIOff.AccountnName
//      //           when I_OperationalAcctgDocItem.FinancialAccountType = 'S'
//      //            then ' '
//      //            else ProfileFI.AccountnName
//      //      end                                  as Text,
//      ProfileFI.AccountnName               as Text,
//      case
//        when I_GLAccountLineItem.DocumentItemText != ''
//        then I_GLAccountLineItem.DocumentItemText
//        else  I_JournalEntry.AccountingDocumentHeaderText
//      end                                  as DienGiai,
//
//      //////Khai.Truong
//      case when $parameters.P_CurrencyType = 'T'
//            then I_GLAccountLineItem.DebitAmountInCoCodeCrcy
//            else I_GLAccountLineItem.DebitAmountInTransCrcy
//      end                                  as DebitAmountInTransCrcy,
//
//      //      I_GLAccountLineItem.DebitAmountInTransCrcy,
//
//      I_GLAccountLineItem.DebitAmountInCoCodeCrcy,
//
//      ////////Khai.Truong
//      case when $parameters.P_CurrencyType = 'T'
//            then I_GLAccountLineItem.CreditAmountInCoCodeCrcy
//            else I_GLAccountLineItem.CreditAmountInTransCrcy
//      end                                  as CreditAmountInTransCrcy,
//
//      //      I_GLAccountLineItem.CreditAmountInTransCrcy,
//
//      I_GLAccountLineItem.CreditAmountInCoCodeCrcy,
//      I_GLAccountLineItem.ControllingArea,
//      I_GLAccountLineItem.Product,
//      I_GLAccountLineItem.CostCenter,
//      I_GLAccountLineItem.MasterFixedAsset,
//      I_GLAccountLineItem.FixedAsset,
//      I_GLAccountLineItem.Customer,
//      I_GLAccountLineItem.Supplier
//}
//where
//          I_GLAccountLineItem.Ledger              = $parameters.P_Ledger
//  and     I_GLAccountLineItem.SourceLedger        = $parameters.P_Ledger
//  and(
//    (
//          $parameters.P_IncRev                    =  'Y'
//    )
//    or(
//          $parameters.P_IncRev                    =  'N'
//      and I_GLAccountLineItem.IsReversal          is initial
//      and I_GLAccountLineItem.IsReversed          is initial
//    )
//  )
//  and(
//    (
//          $parameters.P_CurrencyType              =  'I'
//      and I_GLAccountLineItem.TransactionCurrency =  'VND'
//    )
//    or(
//          $parameters.P_CurrencyType              =  'E'
//      and I_GLAccountLineItem.TransactionCurrency <> I_GLAccountLineItem.CompanyCodeCurrency
//    )
//    or(
//          $parameters.P_CurrencyType              =  'T'
//      and I_GLAccountLineItem.CompanyCodeCurrency =  'VND'
//    )
//  )
