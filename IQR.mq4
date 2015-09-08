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
//|                                                          IQR.mq4 |
//|
//| v3 displayRange
//|    on deleting displayRange cylce thru period: 10 100 200
//|
//| v4
//| 
//| v5 text: draw optimization
//|          Q1 Q3 distributions
//|          v ^ sign on IQR hit
//|
//| v6 on deleting displayRange cylce thru period: 10 100 200 1==HIDE
//|
//| v7 cycling period: 33 100 200 1==HIDE
//|    outliner2_tf ==0 --> hide arrow
//|
//| v8 _p to cycle price mode
//|
//| v9 MTF
//|
//|
//|
//|
//+------------------------------------------------------------------+
/*

  range                    distribution
  Q1 .. Q3                 50%
  
  Q1- 1.5 x IQR  ..  Q1    24.65%

  Q1- 1.5 x IQR 
     ..                    99.3 %
  Q3+ 1.5 x IQR  




*/
#property copyright "Copyright © 2015, Dony Zulkarnaen"

#property indicator_chart_window

#property indicator_buffers 7

#property indicator_color1 Red
#property indicator_color2 Yellow
#property indicator_color3 Blue
#property indicator_color4 Orange
#property indicator_color5 SteelBlue
#property indicator_color6 Pink
#property indicator_color7 Pink


#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 1
#property indicator_width5 1
#property indicator_width6 1
#property indicator_width7 1


extern int period=100;
extern int price_mode=PRICE_CLOSE;
extern int TF=0;     // v9
extern bool draw_outlier=true;
extern double fence=1.5;
extern bool displayRange=true;
extern bool draw2_outlier=true;
extern int outliner2_distance=5; // do not draw outliner2 if consecutive or whithin this bars
extern int outliner2_tf=2;       // M30 --> H2;  H1 --> H4  H4 --> H18
extern bool outliner2_currentTFalso=true;
extern color outliner2_up=MediumVioletRed;
extern color outliner2_dn=CornflowerBlue;
extern bool debug=false;
extern string prefix="zdoiqr_";
extern bool doCalcDistributionPct=true;



int MA_Methods=EMPTY;     // 0=SMA, 1=EMA, 2=SMMA, 3=LWMA

#define ARR_SIZE 30
#define X_shift 0

double p[ARR_SIZE];
double q[ARR_SIZE];

double o[ARR_SIZE];
double h[ARR_SIZE];
double l[ARR_SIZE];
double c[ARR_SIZE];
datetime t[ARR_SIZE];


double Q1buffer[];
double Q2buffer[];
double Q3buffer[];
double LObuffer[];
double HObuffer[];
double LSbuffer[];
double HSbuffer[];

string prefixstr="";
int i_higherTFFlag=0;

int inputted_period;

int  distpct[5];
int  distcnt[5];



//+------------------------------------------------------------------+
double percentile(int p) 
   {
      return((0.1*p/100)*period+0.5);
   
   }




double p_ma=0;
      
//+------------------------------------------------------------------+
void init_arr(int shift)
   {
      // v9
      int shift2=shift;
      
      if(TF!=0)
      {
         shift2=iBarShift(NULL,TF,Time[shift]);
      }
      
      if(MA_Methods!=EMPTY)
         p_ma=iMA(NULL,TF,period,0,MA_Methods,price_mode,shift2);
      
      
    // v9
    int j;
    if(TF==0)
    {
      for(j=period-1;j>=0;j--)
         {
            if(price_mode==PRICE_CLOSE)
               p[j]=Close[shift+j];
            else if(price_mode==PRICE_OPEN)
               p[j]=Open[shift+j];
            else if(price_mode==PRICE_LOW)
               p[j]=Low[shift+j];
            else if(price_mode==PRICE_HIGH)
               p[j]=High[shift+j];
            else if(price_mode==PRICE_MEDIAN)
               p[j]=(High[shift+j]+Low[shift+j])/2;
            else if(price_mode==PRICE_TYPICAL)
               p[j]=(High[shift+j]+Low[shift+j]+Close[shift+j])/3;
            else if(price_mode==PRICE_WEIGHTED)
               p[j]=(High[shift+j]+Low[shift+j]+Close[shift+j]*2)/4;
            
            if(MA_Methods!=EMPTY)
               q[j]=p[j]-p_ma;
         }
     } else    // TF != 0
     {
      for(j=period-1;j>=0;j--)
         {
            if(price_mode==PRICE_CLOSE)
               p[j]=iClose(NULL,TF,shift2+j);
            else if(price_mode==PRICE_OPEN)
               p[j]=iOpen(NULL,TF,shift2+j);
            else if(price_mode==PRICE_LOW)
               p[j]=iLow(NULL,TF,shift2+j);
            else if(price_mode==PRICE_HIGH)
               p[j]=iHigh(NULL,TF,shift2+j);
            else if(price_mode==PRICE_MEDIAN)
               p[j]=(iHigh(NULL,TF,shift2+j)+iLow(NULL,TF,shift2+j))/2;
            else if(price_mode==PRICE_TYPICAL)
               p[j]=(iHigh(NULL,TF,shift2+j)+iLow(NULL,TF,shift2+j)+iClose(NULL,TF,shift2+j))/3;
            else if(price_mode==PRICE_WEIGHTED)
               p[j]=(iHigh(NULL,TF,shift2+j)+iLow(NULL,TF,shift2+j)+iClose(NULL,TF,shift2+j)*2)/4;
            
            if(MA_Methods!=EMPTY)
               q[j]=p[j]-p_ma;
         }
     }
         
      ArraySort(p);

      if(MA_Methods!=EMPTY)
            ArraySort(q);
      
      if(MA_Methods!=EMPTY && shift==0)
         {
            if(debug)            
               Print(p_ma);
            
         }
   }

string PriceModeStr(int price_mode)
   {
      string s="";
      if(price_mode==PRICE_CLOSE)
         s="C";
      else if(price_mode==PRICE_OPEN)
         s="O";
      else if(price_mode==PRICE_LOW)
         s="L";
      else if(price_mode==PRICE_HIGH)
         s="H";
      else if(price_mode==PRICE_MEDIAN)
         s="M";
      else if(price_mode==PRICE_TYPICAL)
         s="T";
      else if(price_mode==PRICE_WEIGHTED)
         s="W";
      return(s);
   }

double Q1, Q2, Q3, IQR, low_outlier, high_outlier;
int j1,j2,j3;

double calcIQR(int shift)
   {

      if(MA_Methods!=EMPTY)
         {
            calcIQR_q(shift);
            return(0);
         }
      
      init_arr(shift);
      j2=(period-1)/2;
      if(1.0*(period-1)/2!=j2)
         Q2=(p[j2]+p[j2+1])/2;
      else 
         Q2=p[j2];
         
      j1=(j2-1)/2;
      if(1.0*(j2-1)/2!=j1)
         Q1=(p[j1]+p[j1+1])/2;
      else 
         Q1=p[j1];
         
      j3=period-j1-1;
      if(1.0*(j2-1)/2!=j1)
         Q3=(p[j3]+p[j3-1])/2;
      else 
         Q3=p[j3];
         
      IQR=Q3-Q1;
      
      low_outlier=Q1-fence*IQR;
      high_outlier=Q3+fence*IQR;
      
   }

double calcIQR_q(int shift)
   {
      init_arr(shift);
      j2=(period-1)/2;
      if(1.0*(period-1)/2!=j2)
         Q2=(q[j2]+q[j2+1])/2;
      else 
         Q2=q[j2];
         
      j1=(j2-1)/2;
      if(1.0*(j2-1)/2!=j1)
         Q1=(q[j1]+q[j1+1])/2;
      else 
         Q1=q[j1];
         
      j3=period-j1-1;
      if(1.0*(j2-1)/2!=j1)
         Q3=(q[j3]+q[j3-1])/2;
      else 
         Q3=q[j3];
         
      Q1=Q1+p_ma;
      Q2=Q2+p_ma;
      Q3=Q3+p_ma;
      
      IQR=Q3-Q1;
      
      low_outlier=Q1-fence*IQR;
      high_outlier=Q3+fence*IQR;
      
   }


//+------------------------------------------------------------------+
// calculate % of p between 0 - LO - Q1 - Q3 - HO - oo
int calcDistributionPct()
   {
      distpct[0]=0;
      distpct[1]=0;
      distpct[2]=0;
      distpct[3]=0;
      distpct[4]=0;
      distcnt[0]=0;
      distcnt[1]=0;
      distcnt[2]=0;
      distcnt[3]=0;
      distcnt[4]=0;
      int maxcnt;
      for(int j=period-1;j>=0;j--)
         {
            if(p[j]<=low_outlier)
               distcnt[0]++;
            else if(p[j]<Q1)
               distcnt[1]++;
            else if(p[j]<=Q3)
               distcnt[2]++;
            else if(p[j]<high_outlier)
               distcnt[3]++;
            else 
               distcnt[4]++;
         }
     distpct[0]=100*distcnt[0]/period;
     distpct[1]=100*distcnt[1]/period;
     distpct[2]=100*distcnt[2]/period;
     distpct[3]=100*distcnt[3]/period;
     distpct[4]=100*distcnt[4]/period;
   }



//+------------------------------------------------------------------+

void DeleteObjects(string iprefix)
{
   string s;
   int l=0;
   l=StringLen(iprefix);
   for(int i=ObjectsTotal()-1;i>=0;i--)
   {
      s=ObjectName(i);
      if(StringSubstr(s,0,l)==iprefix)
         if(s!="")
            ObjectDelete(s);
   }

}


//+------------------------------------------------------------------+
int dispLabel()
   {
      ObjectDelete(prefix+"_l");
      ObjectCreate(prefix+"_l",OBJ_LABEL,0,0,0);
      ObjectSet(prefix+"_l",OBJPROP_XDISTANCE,10);
      ObjectSet(prefix+"_l",OBJPROP_YDISTANCE,10+15*price_mode);
      ObjectSet(prefix+"_l",OBJPROP_CORNER,0);
      ObjectSet(prefix+"_l",OBJPROP_COLOR,Chocolate);
    
      IQRSetText();  
   }

//+------------------------------------------------------------------+
void IQRSetText()
   {
      string s="IQR ";
      
      // v9
      if(TF!=0)
         s=s+string_per(TF)+" ";
      
      s=s+period+PriceModeStr(price_mode)+"; Range ="+DoubleToStr((p[period-1]-p[0])/Point,0);

      if(doCalcDistributionPct && period!=0)
         {
            s=s+" Dist: "+distpct[0]+"% - "+distpct[1]+"% "+distpct[2]+"% "+distpct[3]+"% - "+distpct[4]+"% ";
         }
      
      if(LSbuffer[0]!=EMPTY)
         s=s+" v";
         
      if(HSbuffer[0]!=EMPTY)
         s=s+" ^";
         
      ObjectSetText(prefix+"_l",s);

      if(debug)
         {
            Print("P: ",DoubleToStr(p[period-1],Digits)," - ",DoubleToStr(p[0],Digits));
         }
   
   }
   
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators

   prefixstr=prefix+period+price_mode;
   
   if(displayRange)
      dispLabel();
   
   inputted_period=period;
   
   ArrayResize(p,period);
   ArrayResize(q,period);
   ArrayResize(o,period);
   ArrayResize(h,period);
   ArrayResize(l,period);
   ArrayResize(c,period);
   ArrayResize(t,period);
   
   IndicatorDigits(Digits+1);
   
   ArraySetAsSeries(Q1buffer,true);
   ArraySetAsSeries(Q2buffer,true);
   ArraySetAsSeries(Q3buffer,true);
   ArraySetAsSeries(LObuffer,true);
   ArraySetAsSeries(HObuffer,true);
   ArraySetAsSeries(LSbuffer,true);
   ArraySetAsSeries(HSbuffer,true);
   
   SetIndexBuffer(0,Q1buffer);
   SetIndexBuffer(1,Q2buffer);
   SetIndexBuffer(2,Q3buffer);
   SetIndexBuffer(3,LObuffer);
   SetIndexBuffer(4,HObuffer);
   SetIndexBuffer(5,LSbuffer);
   SetIndexBuffer(6,HSbuffer);
   
   SetIndexLabel(0,"Q1("+period+","+price_mode+")");
   SetIndexLabel(1,"Q2("+period+","+price_mode+")");
   SetIndexLabel(2,"Q3("+period+","+price_mode+")");
   SetIndexLabel(3,"LO("+period+","+price_mode+")");
   SetIndexLabel(4,"HO("+period+","+price_mode+")");
   SetIndexLabel(5,"LS("+period+","+price_mode+")");
   SetIndexLabel(6,"HS("+period+","+price_mode+")");
   
   SetIndexStyle(2,DRAW_LINE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(0,DRAW_LINE);

   SetIndexStyle(3,DRAW_LINE);
   SetIndexStyle(4,DRAW_LINE);
   
   SetIndexStyle(5,DRAW_ARROW);
   SetIndexStyle(6,DRAW_ARROW);


   SetIndexDrawBegin(0,period);
   SetIndexDrawBegin(1,period);
   SetIndexDrawBegin(2,period);
   SetIndexDrawBegin(3,period);
   SetIndexDrawBegin(4,period);
   SetIndexDrawBegin(5,period);
   SetIndexDrawBegin(6,period);
   
   
   if(price_mode==PRICE_HIGH)
     {
         SetIndexStyle(5,DRAW_ARROW,EMPTY,EMPTY,Aqua);
         SetIndexStyle(6,DRAW_ARROW,EMPTY,EMPTY,Aqua);
     }
   if(price_mode==PRICE_LOW)
     {
         SetIndexStyle(5,DRAW_ARROW,EMPTY,EMPTY,Orange);
         SetIndexStyle(6,DRAW_ARROW,EMPTY,EMPTY,Orange);
     }

   i_higherTFFlag=getMyHigherTF(Period(),outliner2_tf);
   
   if(TF==0)
      TF=Period();

   ObjectCreate(prefix+"_p",OBJ_TEXT,0,0,0);
   ObjectSetText(prefix+"_p",PriceModeStr(price_mode));

   ObjectCreate(prefix+"_tf",OBJ_TEXT,0,0,0);
   ObjectSetText(prefix+"_tf",""+TF);


//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   DeleteObjects(prefixstr);
   ObjectDelete(prefix+"_p");
   ObjectDelete(prefix+"_l");
//----
   return(0);
  }

double prevp=0;
datetime prevt=0;

int getMyHigherTF(int tf,int uppertf)
   {
      int tf_flag=0;
      
      if(uppertf==99)
         {
            tf_flag=OBJ_ALL_PERIODS;
            return(tf_flag);
         }
      
      if(uppertf==0)
         {
            tf_flag=0;
            return(tf_flag);
         }
      
      if(tf==0) 
         tf=Period();
         
      if(tf==PERIOD_M1)
         tf_flag=OBJ_PERIOD_M15 | OBJ_PERIOD_M30;
      else if(tf==PERIOD_M5)
         tf_flag=OBJ_PERIOD_M30 | OBJ_PERIOD_H1;
      else if(tf==PERIOD_M15)
         tf_flag=OBJ_PERIOD_H1 | OBJ_PERIOD_H4;
      else if(tf==PERIOD_M30)
         tf_flag=OBJ_PERIOD_H4;
      else if(tf==PERIOD_H1)
         tf_flag=OBJ_PERIOD_H4 | OBJ_PERIOD_D1;
      else if(tf==PERIOD_H4)
         tf_flag=OBJ_PERIOD_D1 | OBJ_PERIOD_W1;
      else if(tf==PERIOD_D1)
         tf_flag=OBJ_PERIOD_W1 | OBJ_PERIOD_MN1;
      else if(tf==PERIOD_W1)
         tf_flag=OBJ_PERIOD_MN1;
                  
         
/*      int periods[9]={1,5,15,30,60,240,1440,10080,43200};
      for(int i=0;i<9;i++)
      {
         if(tf==periods[i])
            break;
      }

      tf_flag = OBJ_ALL_PERIODS << (i+uppertf);
      tf_flag = tf_flag >> (i+uppertf+4);
      tf_flag = tf_flag << 4; */
      
      return(tf_flag);
      
   }

bool may_draw2H=true;
bool may_draw2L=true;
int draw2_Hcounter=0;
int draw2_Lcounter=0;

//+--------------------------------------------------------------------
int DrawArrow(datetime t,double p,int dir)
   {
      if(i_higherTFFlag==0)
         return(0);
         
//      if(Period()==PERIOD_MN1) return(-1);
      string arrobjstr="";
      
      if(dir==1)
         arrobjstr=prefix+Period()+"_"+period+price_mode+"_P"+t+"U";
      else if(dir==-1)
         arrobjstr=prefix+Period()+"_"+period+price_mode+"_P"+t+"D";
      
      ObjectDelete(arrobjstr);
      ObjectCreate(arrobjstr,OBJ_ARROW,0,t,p);
      ObjectSet(arrobjstr,OBJPROP_ARROWCODE,6);
      if(dir==1)
         ObjectSet(arrobjstr,OBJPROP_COLOR,MediumVioletRed);
      else if(dir==-1)
         ObjectSet(arrobjstr,OBJPROP_COLOR,CornflowerBlue);
      ObjectSet(arrobjstr,OBJPROP_TIMEFRAMES,i_higherTFFlag);
   }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {
     int limit;
     int counted_bars=IndicatorCounted();
  //---- check for possible errors
     if(counted_bars<0) return(-1);
  //---- the last counted bar will be recounted
     if(counted_bars>0) counted_bars--;
     limit=Bars-counted_bars;

     string pml,pml2;
   
      //v8
     if(ObjectFind(prefix+"_p")>=0)
      {
         pml=StringSubstr(ObjectDescription(prefix+"_p"),0,1);
         pml2=PriceModeStr(price_mode);
         //Print(ObjectDescription(prefix+"_p"));
         
         if(pml!=pml2)
            {
               //Print("pml:"+pml,"   ",pml2);
               if(pml=="O")
                  price_mode=PRICE_OPEN;
               else if(pml=="H")
                  price_mode=PRICE_HIGH;
               else if(pml=="L")
                  price_mode=PRICE_LOW;
               else 
                  price_mode=PRICE_CLOSE;
               
               ObjectSetText(prefix+"_p",PriceModeStr(price_mode)+
                        StringSubstr(ObjectDescription(prefix+"_p"),1));
               limit=Bars-period-1;
               
               init();
               dispLabel();
            }
         
      }     

      //v9
     if(ObjectFind(prefix+"_tf")>=0)
      {
         pml=ObjectDescription(prefix+"_tf");
         pml2=""+TF;
         
         if(pml!=pml2)
            {
               Print("pml:"+pml,"   ",pml2);
               TF=StrToInteger(pml);
               
               limit=Bars-period-1;
               
               init();
               dispLabel();
            }
         
      }     

  //---------------------------
  // if use new period then re start iqr calc from veru beginning
          if(displayRange)
            {
               if(ObjectFind(prefix+"_l")<0)    // if deleted, cycle trough deifned period: 33 100 200 inputted_period
                  {
                     if(period==33)
                        period=100;
                     else if(period==100)
                        period=200;
                     else if(period==200)
                        period=500;
                     else if(period==500)
                        period=0;
                     else if(period==0)
                        period=33;
                     
                     limit=Bars-period-1;
                     
                     init();
                     dispLabel();

                  }
            }


     if(Bars<period) 
      {
      ObjectSetText(prefix+"_l","IQR"+period+" number of bars < period");
      return(-1);
      }

     int i;

     if(period==0)
       {
         for(i=limit;i>=0;i--)
            {
               LSbuffer[i]=EMPTY;
               HSbuffer[i]=EMPTY;
               Q1buffer[i]=EMPTY;
               Q2buffer[i]=EMPTY;
               Q3buffer[i]=EMPTY;
               LObuffer[i]=EMPTY;
               HObuffer[i]=EMPTY;
               LSbuffer[i]=EMPTY;
               HSbuffer[i]=EMPTY;
            }
         return(0);
       }
     
  //---- main loop
     for(i=limit;i>=0;i--)
       {
         LSbuffer[i]=EMPTY;
         HSbuffer[i]=EMPTY;
         calcIQR(i);
         Q1buffer[i]=Q1;
         Q2buffer[i]=Q2;
         Q3buffer[i]=Q3;
         LObuffer[i]=low_outlier;
         HObuffer[i]=high_outlier;
         if(High[i]>=high_outlier)
            {
               if(draw_outlier)
                  HSbuffer[i]=high_outlier+X_shift*Point;
               if(draw2_outlier && may_draw2H)
                  DrawArrow(Time[i],high_outlier,1);
               draw2_Hcounter=0;
               may_draw2H=false;
            }
            else 
            {
               draw2_Hcounter++;
               if(draw2_Hcounter>=outliner2_distance)
                  may_draw2H=true;
            }
         if(Low[i]<=low_outlier)
            {
               if(draw_outlier)
                  LSbuffer[i]=low_outlier-X_shift*Point;
               if(draw2_outlier && may_draw2L)
                  DrawArrow(Time[i],low_outlier,-1);
               draw2_Lcounter=0;
               may_draw2L=false;
            }
            else 
            {
               draw2_Lcounter++;
               if(draw2_Lcounter>=outliner2_distance)
                  may_draw2L=true;
            }
            
            //Print("dbg"+i);
       }    // for(int i=limit;i>=0;i--)
       
       if(doCalcDistributionPct)
         {
            calcDistributionPct();
         }
       
       if(displayRange)
         {
            if(ObjectFind(prefix+"_l")<0)    // if deleted, cycle trough deifned period: 10 100 200 inputted_period
               {
                  if(period==10)
                     period=100;
                  else if(period==100)
                     period=200;
                  else if(period==200)
                     period=10;
               
                  dispLabel();
               }
            
            IQRSetText();
            
         }     // if(displayRange)
   
   if(prevp!=p[0] && prevt!=Time[0])
      {
      }
      
   if(debug && prevp!=p[0])
      {
         for(i=period;i>=0;i--)
            {
               Print("p[",i,"]=",DoubleToStr(p[i],2));
            }
         Print("Q1=",DoubleToStr(Q1,3));
         Print("Q2=",DoubleToStr(Q2,3));
         Print("Q3=",DoubleToStr(Q3,3));
         
         Print("j1=",j1);
         Print("j2=",j2);
         Print("j3=",j3);

         Print("X2=",1.0*(j2-1)/2);

      }


   prevp=p[0];
   prevt=Time[0];
   
  //---- done
     return(0);
   return(0);
  }
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
