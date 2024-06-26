//+------------------------------------------------------------------+
//|                                            DS-BreakoutProfit.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#property script_show_inputs

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\License\DKLicense.mqh";
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"

#include "CATRBot.mqh"

enum ENUM_BOT_MODE {
  BOT_MODE_BOUNCE = 0,            // На отбой
  BOT_MODE_BREAKOUT = 1,          // На пробой
};

enum ENUM_TP_TYPE {
  TP_TYPE_POINT = 0,              // По пунктам (ориг. пипсам)
  TP_TYPE_ATR = 1                 // По ATR
};

input     group                    "1. ОСНОВНЫЕ НАСТРОЙКИ"
input     ENUM_BOT_MODE            TYPE                                  = BOT_MODE_BREAKOUT;                   // TYPE: Режим работы
input     ENUM_TP_TYPE             TypeTpSL                              = TP_TYPE_POINT;                       // TypeTpSL: Тип TP SL
input     uint                     gTP1                                  = 200;                                 // gTP1: TP 1
input     uint                     SL                                    = 200;                                 // SL: SL
input     ENUM_TIMEFRAMES          AtrTf                                 = PERIOD_H1;                           // AtrTf: Период ATR
input     uint                     AtrPeriod                             = 200;                                 // AtrPeriod: Период ATR
input     double                   AtrRatioTp                            = 100.0;                               // AtrRatioTp: Коэффициент ATR TP
input     double                   AtrRatioSl                            = 100.0;                               // AtrRatioSl: Коэффициент ATR SL
input     uint                     OP_Shift                              = 200;                                 // OP_Shift: Отступ
input     double                   gLot                                  = 0.01;                                // gLot: Лот
input     ulong                    Magic_Number                          = 202406251;                           // Magic_Number: Магик

input     group                    "2. БЕЗУБЫТОК"
input     uint                     points_to_breakeven                   = 120;                                 // points_to_breakeven: Расстояние для перевода в безубыток, пункт (0-откл.)
input     uint                     breakeven                             = 100;                                 // breakeven: Безубыток

input     group                    "3. ТРЕЙЛИНГ СТОП"
input     uint                     TralStart                             = 120;                                 // TralStart: Старт работы трейлинг стопа, пункт (0-откл.)
input     uint                     TralStep                              = 100;                                 // TralStep: Шаг трейлинг стопа

input     group                    "4. ФИЛЬТРЫ"
input     bool                     Close_at_the_end_of_the_day           = true;                                // Close_at_the_end_of_the_day: Закрывать в конце дня
input     uint                     Hour_closing                          = 20;                                  // Hour_closing: Час закрытия

input     bool                     gFlagDay1                             = true;                                // gFlagDay1: Торговать в понедельник
input     uint                     gDay1H1                               = 1;                                   // gDay1H1: Начало торгов понедельника
input     uint                     gDay1H2                               = 22;                                  // gDay1H2: Конец торгов понедельника

input     bool                     gFlagDay2                             = true;                                // gFlagDay2: Торговать во вторник
input     uint                     gDay2H1                               = 1;                                   // gDay2H1: Начало торгов вторника
input     uint                     gDay2H2                               = 22;                                  // gDay2H2: Конец торгов вторника

input     bool                     gFlagDay3                             = true;                                // gFlagDay3: Торговать в среду
input     uint                     gDay3H1                               = 1;                                   // gDay3H1: Начало торгов среды
input     uint                     gDay3H2                               = 22;                                  // gDay3H2: Конец торгов среды

input     bool                     gFlagDay4                             = true;                                // gFlagDay4: Торговать в четверг
input     uint                     gDay4H1                               = 1;                                   // gDay4H1: Начало торгов четверга
input     uint                     gDay4H2                               = 22;                                  // gDay4H2: Конец торгов четверга

input     bool                     gFlagDay5                             = true;                                // gFlagDay5: Торговать в пятницу
input     uint                     gDay5H1                               = 1;                                   // gDay5H1: Начало торгов пятницы
input     uint                     gDay5H2                               = 22;                                  // gDay5H2: Конец торгов пятницы

input     string                   CommentSet                            = "DSBOP";                             // CommentSet: Комментарий

input     group                    "7. ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ"
sinput    LogLevel                 InpLL                                 = LogLevel(INFO);                      // 11.LL: Log Level
          uint                     InpCommentUpdateDelayMs               = 5*1000;                              // Update comment delay

CDKSymbolInfo                      sym;
CATRBot                            bot;

void InitTrade(CDKTrade& _trade, const long _magic, const ulong _slippage) {
  _trade.SetExpertMagicNumber(_magic);
  _trade.SetMarginMode();
  _trade.SetTypeFillingBySymbol(Symbol());
  _trade.SetDeviationInPoints(_slippage);  
  _trade.SetLogger(bot.Logger);
  _trade.LogLevel(LOG_LEVEL_NO);
}

void InitLogger(DKLogger& _logger) {
  _logger.Name = CommentBot;
  _logger.Level = InpLL;
  _logger.Format = "%name%:[%level%] %message%";
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
  MathSrand(GetTickCount());
  
  // Loggers init
  InitLogger(bot.Logger);

  // Проверим режим счета. Нужeн ОБЯЗАТЕЛЬНО ХЕДЖИНГОВЫЙ счет
  CAccountInfo acc;
  if(acc.MarginMode() != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
    bot.Logger.Error("Only hedging mode allowed", true);
    return(INIT_FAILED);
  }
  
  if(!sym.Name(Symbol())) {
    bot.Logger.Error(StringFormat("Symbol %s is not available", Symbol()), true);
    return(INIT_FAILED);
  }
  
  if(MagicBuy == MagicSell) {
    bot.Logger.Error("Set different Magic to sell and to buy", true);
    return(INIT_FAILED);
  } 
  
  if (Type_lot == TYPE_LOT_PAIR && Pair_ratio <= 0) {
    bot.Logger.Error("Коэффициент парности должен быть >0", true);
    return(INIT_FAILED);
  } 
  
  bot.Sym = sym;
  bot.TF = Period();
  InitTrade(bot.TradeBuy, MagicBuy, Slip);
  InitTrade(bot.TradeSell, MagicSell, Slip);
  
  bot.SetTypePos = SetTypePos;
  bot.Max_spread_buy = Max_spread_buy;
  bot.Count_try_buy = Count_try_buy;
  bot.Check_minute = Check_minute;
  bot.Is_comment = Is_comment;
  bot.Type_lot = Type_lot;
  bot.Min_distance = Min_distance;
  bot.Lot = Lot;
  bot.Multi = Multi;
  bot.Pair_ratio = Pair_ratio;
  bot.Min_takeP = Min_takeP;
  bot.DK_MinGridStepPnt = DK_MinGridStepPnt;
  bot.Slip = Slip;
  bot.MagicBuy = MagicBuy;
  bot.MagicSell = MagicSell;
  bot.Max_pos = Max_pos;
  bot.Type_close = Type_close;
  bot.Max_risk = Max_risk;
  bot.Percent_take_1 = Percent_take_1;
  bot.Count_atrMTF_tf_1 = Count_atrMTF_tf_1;
  bot.Time_frame = Time_frame;
  bot.RepeatSignal = RepeatSignal;
  bot.Is_time_frame_2 = Is_time_frame_2;
  bot.Percent_take_2 = Percent_take_2;
  bot.Count_atrMTF_tf_2 = Count_atrMTF_tf_2;
  bot.Time_frame_2 = Time_frame_2;
  bot.Is_time_frame_3 = Is_time_frame_3;
  bot.Percent_take_3 = Percent_take_3;
  bot.Count_atrMTF_tf_3 = Count_atrMTF_tf_3;
  bot.Time_frame_3 = Time_frame_3;
  bot.Show_visual = Show_visual;
  bot.Support_color_1 = Support_color_1;
  bot.Resistance_color_1 = Resistance_color_1;
  bot.Support_color_2 = Support_color_2;
  bot.Resistance_color_2 = Resistance_color_2;
  bot.Support_color_3 = Support_color_3;
  bot.Resistance_color_3 = Resistance_color_3;
  bot.Sup_res_fill = Sup_res_fill;
  bot.Sup_res_width = Sup_res_width;
  bot.Sup_res_style = Sup_res_style;
  bot.CommentBot = CommentBot;  
 
  bot.Init();

  EventSetMillisecondTimer(InpCommentUpdateDelayMs);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
//--- destroy timer
   EventKillTimer();
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()  {
  bot.OnTick();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()  {
  bot.OnTimer();
}

//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()  {
  bot.OnTrade();
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {

   
  }

