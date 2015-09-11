/*
The MIT License (MIT)

Copyright (c) 2015 Dony Zulkarnaen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/



//+------------------------------------------------------------------+
//|                                                     IQRTFCycle.mq4 |
//|                                                            donyz |
//|                                            http://doztronics.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2015, Dony Zulkarnaen"

extern string prefix="zdoiqr_";

bool iqrfound=false;


#include <WinUser32.mqh>
//+------------------------------------------------------------------+
int HstHandle = -1;
string SymbolName;
//+------------------------------------------------------------------+
void UpdateChartWindow() {
	static int hwnd = 0;
 
	if(hwnd == 0) {
		hwnd = WindowHandle(Symbol(), Period());
//		if(hwnd != 0) Print("Chart window detected");
	}
	if(hwnd != 0) if(PostMessageA(hwnd, WM_COMMAND, 0x822c, 0) == 0) hwnd = 0;
	//if(hwnd != 0) UpdateWindow(hwnd);
}

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   int obj_total=ObjectsTotal();
   
   string name;
   string pml,pml2;

   int tf=0, tf2=0;
   
   for(int i=obj_total-1;i>=0;i--)
    {
     name=ObjectName(i);
     if(StringFind(name,prefix)>=0)
      {
//         Print(StringSubstr(name,StringLen(name)-2));
       if(StringSubstr(name,StringLen(name)-3)=="_tf")
         {
            Print(i,"Object name for object #",i," is " + name);

            pml =ObjectDescription(name);
            
            Print(i,"old string: " + ObjectDescription(name));

            tf=StrToInteger(pml);
            if(tf==0)
               tf=Period();
            
            tf2=0;
            
            switch(tf)
            {
               case 1:
                  tf2=5;
                  break;
               case 5:
                  tf2=15;
                  break;
               case 15:
                  tf2=30;
                  break;
               case 30:
                  tf2=60;
                  break;
               case 60:
                  tf2=240;
                  break;
               case 240:
                  tf2=1440;
                  break;
               case 1440:
                  tf2=10080;
                  break;
               case 10080:
                  tf2=43200;
                  break;
               case 43200:
               default:
                  tf2=Period();
                  break;
            }
               
            ObjectSetText(name,""+tf2);

            Print(i,"new string: " + ObjectDescription(name));
            
         iqrfound=true;
         break;
         }
       }
    }       //    for(int i=obj_total-1;i>=0;i--)
    
    if(iqrfound)
      {
         UpdateChartWindow();
      }

//----
   return(0);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

string string_per(int per)
{
   if (per == 1)     return("M1");
   if (per == 5)     return("M5");
   if (per == 15)    return("M15");
   if (per == 30)    return("M30");
   if (per == 60)    return("H1");
   if (per == 240)   return("H4");
   if (per == 1440)  return("D1");
   if (per == 10080) return("W1");
   if (per == 43200) return("MN1");
return("Period Unknown");
}
//+------------------------------------------------------------------+
int getPeriod(string s)
   {
      if(s=="MN" || s=="MN1")
         return(PERIOD_MN1);
      else if(s=="W1" || s=="WK1")
         return(PERIOD_W1);
      else if(s=="D1")
         return(PERIOD_D1);
      else if(s=="H4")
         return(PERIOD_H4);
      else if(s=="H1")
         return(PERIOD_H1);
      else if(s=="M30")
         return(PERIOD_M30);
      else if(s=="M15")
         return(PERIOD_M15);
      else if(s=="M5")
         return(PERIOD_M5);
      else if(s=="M5")
         return(PERIOD_M5);
      else if(s=="M1")
         return(PERIOD_M1);
      else return(-1);
   }
