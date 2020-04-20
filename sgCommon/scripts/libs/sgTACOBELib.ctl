void connectTACOCommand(string dpName, string cmd)
{      
  int ret; 
  string s = "cmd /c start D:\\putty\\putty.exe -load taco-dpl -l admin -m D:\\putty\\" + cmd;
//  DebugTN("sgTACOBE.ctl;TACO Connect full command:"  + s);
  
  ret=system(s);
  
//  DebugTN("sgTACOBE.ctl;TACO Connect ret:"  + ret);
 }
