database TypeAndId;
foreach "pvssglob.txt" {
  record pvssglobalrec {
        field noOfLanguages  = 1;
  }
}
foreach "systemid.txt" {
  record systemidentrec {
        field systemNr              = 1;
        field highestAssignedDpId   = 2;
        field highestAssignedTypeId = 3;
        field firstName             = 4;
  }
}
foreach "dpconfig.txt" {
  record dpconfigidentrec {
        field systemNr  = 1;
        field configNr  = 2;
        field firstName = 3;
  }
}
foreach "fixednum.txt" {
  record fixednumberidentrec {
        field systemNr  = 1;
        field category  = 2;
        field id        = 3;
        field firstName = 4;
  }
}
foreach "datapoin.txt" {
  record datapointidentrec {
        field systemNr  = 1;
        field dpNr      = 2;
        field typeNr    = 3;
        field firstName = 4;
  }
}
foreach "dptypeid.txt" {
  record dptypeidentrec {
        field systemNr      = 1;
        field typeNr        = 2;
        field firstFreeElId = 3;
        field versionNr     = 4;
        field flags         = 5;
        field firstName     = 6;
        field rootNode      = 7;
  }
}
foreach "dpaliasi.txt" {
  record dpaliasidentrec {
        field systemNr         = 1;
        field dpNr             = 2;
        field elNr             = 3;
        field firstAliasName   = 4;
        field firstCommentName = 5;
  }
}
end;
