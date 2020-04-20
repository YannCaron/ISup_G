public const int MSGBOX_INFO = 0;
public const int MSGBOX_WARNING = 1;
public const int MSGBOX_ALERT = 2;
public const int MSGBOX_QUESTION = 3;
public const int MSGBOX_SAVE = 4;

public const int MSGBOX_OK_YES = 1;
public const int MSGBOX_CANCEL_NO = 0;

bool showDialog(int type, string title, string content) {
  dyn_float dreturnf;
  dyn_string dreturns;
 
  int x, y;
  x = 300;
  y = 100;
  ChildPanelOnCentralModalReturn("sgFw/sgFwMessageBox.pnl","AlertPanel",
                          makeDynString("$type:" + type, "$title:" + title, "$content:" + content),
                          dreturnf, dreturns);
 
  return dreturnf[1] == MSGBOX_OK_YES;
}
