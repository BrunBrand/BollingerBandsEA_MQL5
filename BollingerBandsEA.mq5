//+------------------------------------------------------------------+
//|                                   BollingerBand_OrchardForex.mq5 |
//|                                         brandon.brunno@gmail.com |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "brandon.brunno@gmail.com"
#property link      "https://www.mql5.com"
#property version   "1.00"

input int InpBandsPeriods = 20;
input double InpBandsDeviations = 2.0;
input ENUM_APPLIED_PRICE InpBandsAppliedPrice = PRICE_CLOSE;

input double InpTPDeviations = 1.0;
input double InpSLDeviations = 1.0;

input double InpVolume = 0.01;
input int InpMagicNumber = 21312;
input string InpTradeComment = __FILE__;

#include  "..\..\Include\Trade\Trade.mqh"



MqlRates rates[];
MqlTick ticks;
MqlTradeRequest request;
MqlTradeResult result;

double bollingerHandle;
double bollingerBufferUpper[];
double bollingerBufferMiddle[];
double bollingerBufferLower[];

CTrade trade;

int adjustDigits;

int OnInit(){

   
   bollingerHandle = iBands(_Symbol,PERIOD_CURRENT,InpBandsPeriods,0,InpBandsDeviations,InpBandsAppliedPrice);

   ArraySetAsSeries(bollingerBufferUpper,true);
   ArraySetAsSeries(bollingerBufferMiddle,true);
   ArraySetAsSeries(bollingerBufferLower,true);

   adjustDigits = _Digits==5 || _Digits==5 ? 10 : 1;


   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason){

   
}

void OnTick(){
   if(!IsNewBar()) return;
   

   
   if(CopyRates(_Symbol,PERIOD_CURRENT,0,3,rates)<0) return;
   if(!SymbolInfoTick(_Symbol,ticks)) return;
   
   if(CopyBuffer(bollingerHandle,0,0,3,bollingerBufferMiddle)<0) return;
   if(CopyBuffer(bollingerHandle,1,0,3,bollingerBufferUpper)<0) return;
   if(CopyBuffer(bollingerHandle,2,0,3,bollingerBufferLower)<0) return;
   
   
   
   
   if(rates[2].close>bollingerBufferUpper[2] && rates[1].close < bollingerBufferUpper[1]){
      OpenOrder(ORDER_TYPE_SELL_STOP, rates[1].low, (bollingerBufferUpper[1]-bollingerBufferLower[1]));
      if(result.retcode==10008 || result.retcode == 10009){
         Print("Order Sent");
      }else{
         Print("Order Error - erro: ", GetLastError());
         ResetLastError();
      }
   }
   
   if(rates[2].close < bollingerBufferLower[2] && rates[1].close>bollingerBufferLower[1]){
      OpenOrder(ORDER_TYPE_BUY_STOP,rates[1].high, (bollingerBufferUpper[1]-bollingerBufferLower[1]));
      if(result.retcode==10008 || result.retcode == 10009){
         Print("Order Sent");
      }else{
         Print("Order Error - erro: ", GetLastError());
         ResetLastError();
      }
   }
   
   
   
   return;
}



bool IsNewBar(){
   
   datetime        now        = iTime(_Symbol,PERIOD_CURRENT,0);
   static datetime prevTime   = now;
   
   if(prevTime==now) return false;
   prevTime = now;
   return true;
   
   
}


int OpenOrder(ENUM_ORDER_TYPE orderType, double entryPrice, double channelWidth){

   ZeroMemory(request);
   ZeroMemory(result);

   request.deviation =  channelWidth/(2*InpBandsDeviations);
   request.price     =  entryPrice = NormalizeDouble(entryPrice,_Digits);
   request.action       = TRADE_ACTION_DEAL;
   request.magic        = InpMagicNumber;
   request.symbol       = _Symbol;
   request.volume       = InpVolume;
   request.type_filling = ORDER_FILLING_FOK;

   double tp = request.deviation * InpTPDeviations *adjustDigits;
   double sl = request.deviation * InpSLDeviations *adjustDigits;
   
   request.expiration = iTime(_Symbol,PERIOD_CURRENT,0) + PeriodSeconds()-1;

   double stopLevel = Point() * SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   Print(stopLevel);
   if(orderType%2==ORDER_TYPE_BUY){
   
      
      //if(ticks.ask>=(entryPrice-stopLevel)){
         request.price = ticks.ask;
         request.type = ORDER_TYPE_BUY;
      //}
      
      request.tp = NormalizePrice(entryPrice+tp);
      request.sl = NormalizePrice(entryPrice-sl);   
   
      Print(request.sl);
      Print("wwww");
   } else if(orderType%2==ORDER_TYPE_SELL){
      
      //if(ticks.bid<=(entryPrice+stopLevel)){
         request.price = ticks.bid;
         request.type = ORDER_TYPE_SELL;
      //}
      request.tp = NormalizePrice(entryPrice-tp);
      request.sl = NormalizePrice(entryPrice+sl);
      
   } else return 0;
   return OrderSend(request,result);

}

double round_nearest(double v, double to){ return to * MathRound(v / to); }
double round_down(   double v, double to){ return to * MathFloor(v / to); }
double round_up(     double v, double to){ return to * MathCeil( v / to); }

double NormalizePrice(double p, double d=0.0){
   double tickSize    = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(d > 0)   return round_up(p,      tickSize);
   if(d < 0)   return round_down(p,    tickSize);
               return round_nearest(p, tickSize);
}


double   NormalizeLots(double lots){
   double lotStep     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   return round_down(lots, lotStep);
   return lots;
}
