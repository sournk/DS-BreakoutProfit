//+------------------------------------------------------------------+
//|                                           CBreakoutProfitBot.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayLong.mqh>

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\CDKLogger.mqh"
#include "Include\DKStdLib\TradingManager\CDKPositionInfo.mqh"
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLBE.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLStep.mqh"
#include "Include\DKStdLib\Drawing\DKChartDraw.mqh"

#include "Include\DKStdLib\Bot\CDKBaseBot.mqh"

enum ENUM_TIMEFRAME_CUSTOM {
  TIMEFRAME_CUSTOM_CURRENT = 0,        // Current
  TIMEFRAME_CUSTOM_M1      = 1,        // M1
  TIMEFRAME_CUSTOM_M5      = 5,        // M5
  TIMEFRAME_CUSTOM_M15     = 15,       // M15
  TIMEFRAME_CUSTOM_M30     = 30,       // M30
  TIMEFRAME_CUSTOM_H1      = 60,       // H1
  TIMEFRAME_CUSTOM_H4      = 4*60,     // H4
  TIMEFRAME_CUSTOM_D1      = 24*60,    // D1
  TIMEFRAME_CUSTOM_W1      = 24*60*7,  // W1
  TIMEFRAME_CUSTOM_MN1     = 24*60*30  // MN1
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES EnumTimeframeCustomToDefault(const ENUM_TIMEFRAME_CUSTOM _tf_custom) {
  if (_tf_custom == TIMEFRAME_CUSTOM_CURRENT)  return PERIOD_CURRENT;
  if (_tf_custom == TIMEFRAME_CUSTOM_M1)   return PERIOD_M1;
  if (_tf_custom == TIMEFRAME_CUSTOM_M5)   return PERIOD_M5;
  if (_tf_custom == TIMEFRAME_CUSTOM_M15)  return PERIOD_M15;
  if (_tf_custom == TIMEFRAME_CUSTOM_M30)  return PERIOD_M30;
  if (_tf_custom == TIMEFRAME_CUSTOM_H1)   return PERIOD_H1;
  if (_tf_custom == TIMEFRAME_CUSTOM_H4)   return PERIOD_H4;
  if (_tf_custom == TIMEFRAME_CUSTOM_D1)   return PERIOD_D1;
  if (_tf_custom == TIMEFRAME_CUSTOM_W1)   return PERIOD_W1;
  if (_tf_custom == TIMEFRAME_CUSTOM_MN1)  return PERIOD_MN1;

  return PERIOD_M5;
}

enum ENUM_BOT_MODE {
  BOT_MODE_BOUNCE = 1,            // На отбой
  BOT_MODE_BREAKOUT = 0,          // На пробой
};

enum ENUM_TP_TYPE {
  TP_TYPE_POINT = 0,              // По пунктам (ориг. пипсам)
  TP_TYPE_ATR = 1                 // По ATR
};

class CBreakoutProfitBot : public CDKBaseBot {
 public:
  ENUM_BOT_MODE            TYPE;
  ENUM_TP_TYPE             TypeTpSL;
  uint                     gTP1;
  uint                     SL;
  ENUM_TIMEFRAMES          AtrTf;
  uint                     AtrPeriod;
  double                   AtrRatioTp;
  double                   AtrRatioSl;
  uint                     OP_Shift;
  double                   gLot;
  ulong                    Magic_Number;
  uint                     points_to_breakeven;
  uint                     breakeven;
  uint                     TralStart;
  uint                     TralStep;
  uint                     DKMaxSpreadToPlaceOrder;
  bool                     Close_at_the_end_of_the_day;
  uint                     Hour_closing;
  bool                     gFlagDay1;
  uint                     gDay1H1;
  uint                     gDay1H2;
  bool                     gFlagDay2;
  uint                     gDay2H1;
  uint                     gDay2H2;
  bool                     gFlagDay3;
  uint                     gDay3H1;
  uint                     gDay3H2;
  bool                     gFlagDay4;
  uint                     gDay4H1;
  uint                     gDay4H2;
  bool                     gFlagDay5;
  uint                     gDay5H1;
  uint                     gDay5H2;

  long                     OrderBuy;
  long                     OrderSell;

  int                      ATRHandle;

  void                     CBreakoutProfitBot::GetLevels(double& _high, double& _low, datetime& _dt);
  double                   CBreakoutProfitBot::GetATR();

  bool                     CBreakoutProfitBot::IsTradeAllowed();
  bool                     CBreakoutProfitBot::IsPriceBetweenLevels();

  datetime                 CBreakoutProfitBot::TrimExpirationTime(const datetime _dt);

  ulong                    CBreakoutProfitBot::PlaceOrderStop(const ENUM_POSITION_TYPE _dir);
  ulong                    CBreakoutProfitBot::PlaceOrderLimit(const ENUM_POSITION_TYPE _dir);
  void                     CBreakoutProfitBot::PlaceOrders();
  void                     CBreakoutProfitBot::DeleteAllMarketOrders();  

  void                     CBreakoutProfitBot::MovePosToBE(const ulong _pos_id);
  void                     CBreakoutProfitBot::CheckAndMoveToBE();

  void                     CBreakoutProfitBot::ChangePosTSL(const ulong _pos_id);
  void                     CBreakoutProfitBot::CheckAndChangesToTSL();

  void                     CBreakoutProfitBot::ClosePosesAtDayEnd();

  void                     CBreakoutProfitBot::Draw(const ENUM_POSITION_TYPE _dir, 
                                                    const datetime _dt, const datetime _from, const datetime _to,
                                                    const double _price, const double _sl, const double _tp);

  void                     CBreakoutProfitBot::InitChild();
  bool                     CBreakoutProfitBot::Check(void);

  // Event Handlers
  void                     CBreakoutProfitBot::OnTick(void);
  void                     CBreakoutProfitBot::OnBar(void);
  //void                     CBreakoutProfitBot::OnTrade(void);
  //void                     CBreakoutProfitBot::OnTimer(void);
};


//+------------------------------------------------------------------+
//| Inits bot
//+------------------------------------------------------------------+
void CBreakoutProfitBot::InitChild() {
  OrderBuy  = -1;
  OrderSell = -1;

  ATRHandle = iATR(Sym.Name(), TF, AtrPeriod);
  
  // Detele all pending orders
  DeleteAllMarketOrders();  
}

//+------------------------------------------------------------------+
//| Check bot's inputs
//+------------------------------------------------------------------+
bool CBreakoutProfitBot::Check(void) {
  bool res = CDKBaseBot::Check();

  if (ATRHandle < 0) {
    Logger.Error("ATR load failed", true);
    res = false;
  }

  return res;
}

//+------------------------------------------------------------------+
//| OnTick Handler
//+------------------------------------------------------------------+
void CBreakoutProfitBot::OnTick(void) {
  CheckAndMoveToBE();      // 1. Moves poses to BE
  CheckAndChangesToTSL();  // 2. Moves poses to TSL
  ClosePosesAtDayEnd();    // 3. Close all poses at the end of the day
  PlaceOrders();           // 4. Place new orders


  CDKBaseBot::OnTick(); // Check new bar and show comment
}

//+------------------------------------------------------------------+
//| OnBar Handler
//+------------------------------------------------------------------+
void CBreakoutProfitBot::OnBar(void) {
  OrderBuy  = -1;
  OrderSell = -1;
  if (IsPriceBetweenLevels()) {
    OrderBuy  = 0;
    OrderSell = 0;
  }
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Bot's logic
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Returns HIGH and LOW levels
//+------------------------------------------------------------------+
void CBreakoutProfitBot::GetLevels(double& _high, double& _low, datetime& _dt) {
  _high = iHigh(Sym.Name(), TF, 1); // For breakout BUY use HIGH level
  _low  = iLow(Sym.Name(), TF, 1); // For breakout SELL use LOW level
  _dt   = iTime(Sym.Name(), TF, 1); // Time of prev bar
}

//+------------------------------------------------------------------+
//| Returns ATR value
//+------------------------------------------------------------------+
double CBreakoutProfitBot::GetATR() {
  double res[];
  if (CopyBuffer(ATRHandle, 0, 0, 1, res) > 0)
    return res[0];

  return 0.0;
}

//+------------------------------------------------------------------+
//| Check trade is allowed
//+------------------------------------------------------------------+
bool CBreakoutProfitBot::IsTradeAllowed() {
  MqlDateTime dt;
  if (!TimeToStruct(TimeCurrent(), dt)) return false;

  if (gFlagDay1 && dt.day_of_week == 1)
    if (dt.hour >= (int)gDay1H1 && dt.hour <= (int)gDay1H2) return true;
  if (gFlagDay2 && dt.day_of_week == 2)
    if (dt.hour >= (int)gDay2H1 && dt.hour <= (int)gDay2H2) return true;
  if (gFlagDay3 && dt.day_of_week == 3)
    if (dt.hour >= (int)gDay3H1 && dt.hour <= (int)gDay3H2) return true;
  if (gFlagDay4 && dt.day_of_week == 4)
    if (dt.hour >= (int)gDay4H1 && dt.hour <= (int)gDay4H2) return true;
  if (gFlagDay5 && dt.day_of_week == 5)
    if (dt.hour >= (int)gDay5H1 && dt.hour <= (int)gDay5H2) return true;

  return false;
}


//+------------------------------------------------------------------+
//| Checks ASK/BID inside levels
//+------------------------------------------------------------------+
bool CBreakoutProfitBot::IsPriceBetweenLevels() {
  // Check ASK/BID between levels
  if (!Sym.RefreshRates()) return false;
  double ask = Sym.Ask();
  double bid = Sym.Bid();
  double high = 0.0;
  double low  = 0.0;
  datetime dt  = 0;
  GetLevels(high, low, dt);

  if (ask > low && ask < high && bid > low && bid < high)
    return true;

  return false;
}

//+------------------------------------------------------------------+
//| Trim expiration time with time filter to gDay*H2 hour
//+------------------------------------------------------------------+
datetime CBreakoutProfitBot::TrimExpirationTime(const datetime _dt) {
  MqlDateTime mql_dt;
  if (!TimeToStruct(_dt, mql_dt)) return _dt;
  if (mql_dt.day_of_week == 1 && gFlagDay1) { mql_dt.hour = (int)gDay1H2; mql_dt.min = 0; mql_dt.sec = 0; }
  if (mql_dt.day_of_week == 2 && gFlagDay2) { mql_dt.hour = (int)gDay2H2; mql_dt.min = 0; mql_dt.sec = 0; }
  if (mql_dt.day_of_week == 3 && gFlagDay3) { mql_dt.hour = (int)gDay3H2; mql_dt.min = 0; mql_dt.sec = 0; }
  if (mql_dt.day_of_week == 4 && gFlagDay4) { mql_dt.hour = (int)gDay4H2; mql_dt.min = 0; mql_dt.sec = 0; }
  if (mql_dt.day_of_week == 5 && gFlagDay5) { mql_dt.hour = (int)gDay5H2; mql_dt.min = 0; mql_dt.sec = 0; }
  
  return StructToTime(mql_dt);
}

//+------------------------------------------------------------------+
//| Places STOP orders
//+------------------------------------------------------------------+
ulong CBreakoutProfitBot::PlaceOrderStop(const ENUM_POSITION_TYPE _dir) {
  datetime current_bar_dt = iTime(Sym.Name(), TF, 0); // Time of curr bar

  // Get levels
  double high = 0.0;
  double low  = 0.0;
  datetime level_bar_dt = 0;
  GetLevels(high, low, level_bar_dt);

  ENUM_ORDER_TYPE order_type;
  double price = 0.0;
  if (_dir == POSITION_TYPE_BUY) {
    price = high;
    order_type = ORDER_TYPE_BUY_STOP;
  } else {
    price = low;
    order_type = ORDER_TYPE_SELL_STOP;
  }

  price = Sym.AddToPrice(_dir, price, Sym.PointsToPrice(OP_Shift)); // Shift EP

  double lot = Sym.NormalizeLot(gLot);

  double sl_dist = 0.0;
  double tp_dist = 0.0;
  if (TypeTpSL == TP_TYPE_ATR) {
    sl_dist = GetATR()*AtrRatioSl;
    tp_dist = GetATR()*AtrRatioTp;
  } else {
    sl_dist = Sym.PointsToPrice(SL);
    tp_dist = Sym.PointsToPrice(gTP1);
  }
  double sl = Sym.AddToPrice(_dir, price, -1*sl_dist);
  double tp = Sym.AddToPrice(_dir, price, tp_dist);

  datetime expiration = current_bar_dt + PeriodSeconds(TF)-1;
  expiration = TrimExpirationTime(expiration);

  string comment = StringFormat("%s.%s|%s", Logger.Name, PositionTypeToString(_dir, true), TimeToString(level_bar_dt));

  ulong res = Trade.OrderOpen(Sym.Name(), order_type, lot, 0, price, sl, tp, ORDER_TIME_SPECIFIED, expiration, comment);
  if (res > 0) {
    Draw(_dir, level_bar_dt, TimeCurrent(), expiration, price, sl, tp);
    Logger.Info(StringFormat("%s/%d: T=%I64u; D=%s; L=%f; EP=%f; SL=%f; TP=%f; EXP=%s",
                             __FUNCTION__, __LINE__,
                             res, PositionTypeToString(_dir),
                             lot, price, sl, tp, TimeToString(expiration)));
  }
  else
    Logger.Error(StringFormat("%s/%d: T=%I64u; D=%s; L=%f; EP=%f; SL=%f; TP=%f; EXP=%s; RETCODE=%d; MSG=%s",
                              __FUNCTION__, __LINE__,
                              res, PositionTypeToString(_dir),
                              lot, price, sl, tp, TimeToString(expiration),
                              Trade.ResultRetcode(), Trade.ResultRetcodeDescription()));

  return res;
}

//+------------------------------------------------------------------+
//| Places STOP LIMIT orders
//+------------------------------------------------------------------+
ulong CBreakoutProfitBot::PlaceOrderLimit(const ENUM_POSITION_TYPE _dir) {
  datetime current_bar_dt = iTime(Sym.Name(), TF, 0); // Time of curr bar

  // Get levels
  double high = 0.0;
  double low  = 0.0;
  datetime level_bar_dt = 0;
  GetLevels(high, low, level_bar_dt);

  ENUM_ORDER_TYPE order_type;
  double price = 0.0;
  if (_dir == POSITION_TYPE_BUY) {
    price = low;
    order_type = ORDER_TYPE_BUY_LIMIT;
  } else {
    price = high;
    order_type = ORDER_TYPE_SELL_LIMIT;
  }

  price = Sym.AddToPrice(_dir, price, Sym.PointsToPrice(OP_Shift)); // Shift EP

  double lot = Sym.NormalizeLot(gLot);

  double sl_dist = 0.0;
  double tp_dist = 0.0;
  if (TypeTpSL == TP_TYPE_ATR) {
    sl_dist = GetATR()*AtrRatioSl;
    tp_dist = GetATR()*AtrRatioTp;
  } else {
    sl_dist = Sym.PointsToPrice(SL);
    tp_dist = Sym.PointsToPrice(gTP1);
  }
  double sl = Sym.AddToPrice(_dir, price, -1*sl_dist);
  double tp = Sym.AddToPrice(_dir, price, tp_dist);

  datetime expiration = current_bar_dt + PeriodSeconds(TF)-1;
  expiration = TrimExpirationTime(expiration);
  string comment = StringFormat("%s.%s|%s", Logger.Name, PositionTypeToString(_dir, true), TimeToString(level_bar_dt));

  ulong res = Trade.OrderOpen(Sym.Name(), order_type, lot, 0, price, sl, tp, ORDER_TIME_SPECIFIED, expiration, comment);
  if (res > 0) {
    Draw(_dir, level_bar_dt, TimeCurrent(), expiration, price, sl, tp);
    Logger.Info(StringFormat("%s/%d: T=%I64u; D=%s; L=%f; EP=%f; SL=%f; TP=%f; EXP=%s",
                             __FUNCTION__, __LINE__,
                             res, PositionTypeToString(_dir),
                             lot, price, sl, tp, TimeToString(expiration)));
  }
  else
    Logger.Error(StringFormat("%s/%d: T=%I64u; D=%s; L=%f; EP=%f; SL=%f; TP=%f; EXP=%s; RETCODE=%d; MSG=%s",
                              __FUNCTION__, __LINE__,
                              res, PositionTypeToString(_dir),
                              lot, price, sl, tp, TimeToString(expiration),
                              Trade.ResultRetcode(), Trade.ResultRetcodeDescription()));

  return res;
}

//+------------------------------------------------------------------+
//| Places both orders
//+------------------------------------------------------------------+
void CBreakoutProfitBot::PlaceOrders() {
  // 01. Check trading time
  if (!IsTradeAllowed()) return;

  // 02. Check ASK/BID between level
  if (!IsPriceBetweenLevels()) return;

  // 03. Check max spread allowed
  if (DKMaxSpreadToPlaceOrder > 0) {
    if (!Sym.RefreshRates()) return;
    double spread_curr = MathAbs(Sym.Ask() - Sym.Bid());
    double spread_allowed = Sym.PointsToPrice(DKMaxSpreadToPlaceOrder);
    if (spread_curr > spread_allowed) {
      if (DEBUG >= Logger.Level)
        Logger.Debug(StringFormat("%s/%d: Spread %f is too big %f",
                                  __FUNCTION__, __LINE__,
                                  spread_curr, spread_allowed));
      return;
    }
  }

  // 03. Try to place orders
  if (TYPE == BOT_MODE_BREAKOUT) {
    if (OrderBuy  == 0) OrderBuy  = (long)PlaceOrderStop(POSITION_TYPE_BUY);
    if (OrderSell == 0) OrderSell = (long)PlaceOrderStop(POSITION_TYPE_SELL);
  }

  if (TYPE == BOT_MODE_BOUNCE) {
    if (OrderBuy == 0)  OrderBuy  = (long)PlaceOrderLimit(POSITION_TYPE_BUY);
    if (OrderSell == 0) OrderSell = (long)PlaceOrderLimit(POSITION_TYPE_SELL);
  }
}

//+------------------------------------------------------------------+
//| Scan all market orders and delete all of them
//+------------------------------------------------------------------+
void CBreakoutProfitBot::DeleteAllMarketOrders() {
  CArrayLong order_list;
  COrderInfo order;
  for(int i=0;i<OrdersTotal();i++) {
    if (!order.SelectByIndex(i)) continue;
    if (order.Symbol() != Sym.Name()) continue;
    if (order.Magic() != Magic_Number) continue;
    order_list.Add(order.Ticket());     
  }
  
  for(int i=0;i<order_list.Total();i++) {
    long ticket = order_list.At(i);
    bool res= Trade.OrderDelete(ticket);
    string log_msg = StringFormat("%s/%d: TICKET=%I64u; RET_CODE=%d; MSG=%s", 
                               __FUNCTION__, __LINE__,
                               ticket, Trade.ResultRetcode(), Trade.ResultRetcodeDescription()
                               );
    Logger.Assert(res, 
                  log_msg, INFO,
                  log_msg, ERROR);
  }
}

//+------------------------------------------------------------------+
//| Moves Pos to BE                                                                  |
//+------------------------------------------------------------------+
void CBreakoutProfitBot::MovePosToBE(const ulong _pos_id) {
  int activation_distance_from_open_point = (int)points_to_breakeven;
  int be_extra_shift_from_open_point = (int)points_to_breakeven-(int)breakeven;

  if (activation_distance_from_open_point <= 0) return;

  CDKTSLBE pos;
  if (!pos.SelectByTicket(_pos_id)) return; // No pos found

  double sl_old = pos.StopLoss();
  pos.Init(activation_distance_from_open_point, be_extra_shift_from_open_point);
  bool res = pos.Update(Trade, false);
  pos.SelectByTicket(_pos_id);
  double sl_new = pos.StopLoss();

  if (!res)
    Logger.Assert(pos.ResultRetcode() >= ERR_USER_ERROR_FIRST,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__,
                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), DEBUG,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__,
                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), ERROR);
  else
    Logger.Info(StringFormat("%s/%d: T=%I64u; RET_CODE=DONE; SL=%f->%f", __FUNCTION__, __LINE__, _pos_id, sl_old, sl_new));
}

//+------------------------------------------------------------------+
//| Moves all poses to BE                                                                  |
//+------------------------------------------------------------------+
void CBreakoutProfitBot::CheckAndMoveToBE() {
  if (points_to_breakeven <= 0) return;

  for(int i=0;i<Poses.Total();i++)
    MovePosToBE(Poses.At(i));
}

//+------------------------------------------------------------------+
//| Serves TSL
//+------------------------------------------------------------------+
void CBreakoutProfitBot::ChangePosTSL(const ulong _pos_id) {
  int activation_distance_from_open_point = (int)TralStart + (int)TralStep;
  int be_extra_shift_from_open_point = (int)TralStart;

  if (activation_distance_from_open_point <= 0) return;

  CDKTSLStep pos;
  if (!pos.SelectByTicket(_pos_id)) return; // No pos found

  double sl_old = pos.StopLoss();
  pos.Init(activation_distance_from_open_point, be_extra_shift_from_open_point);
  bool res = pos.Update(Trade, false);
  pos.SelectByTicket(_pos_id);
  double sl_new = pos.StopLoss();

  if (!res)
    Logger.Assert(pos.ResultRetcode() >= ERR_USER_ERROR_FIRST,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__,
                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), DEBUG,
                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__,
                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), ERROR);
  else
    Logger.Info(StringFormat("%s/%d: T=%I64u; RET_CODE=DONE; SL=%f->%f", __FUNCTION__, __LINE__, _pos_id, sl_old, sl_new));
}

//+------------------------------------------------------------------+
//| Serves all pos to TSL
//+------------------------------------------------------------------+
void CBreakoutProfitBot::CheckAndChangesToTSL() {
  if (TralStart <= 0) return;

  for(int i=0;i<Poses.Total();i++)
    ChangePosTSL(Poses.At(i));
}

//+------------------------------------------------------------------+
//| Close all poses
//+------------------------------------------------------------------+
void CBreakoutProfitBot::ClosePosesAtDayEnd() {
  if (!Close_at_the_end_of_the_day) return;

  MqlDateTime dt;
  if (!TimeToStruct(TimeCurrent(), dt)) return;
  if (dt.hour != Hour_closing) return;

  CDKPositionInfo pos;
  for(int i=0;i<Poses.Total();i++)
    Trade.PositionClose(Poses.At(i));
}

//+------------------------------------------------------------------+
//| Draw all patterns
//+------------------------------------------------------------------+
void CBreakoutProfitBot::Draw(const ENUM_POSITION_TYPE _dir, 
                              const datetime _dt, const datetime _from, const datetime _to,
                              const double _price, const double _sl, const double _tp) {
  color clr = (_dir == POSITION_TYPE_BUY) ? clrGreen : clrRed;
                              
  TrendLineCreate(0,
                  StringFormat("%s|LEV|%s|%s", Logger.Name, PositionTypeToString(_dir), TimeToString(_dt)),
                  StringFormat("%s level %s", PositionTypeToString(_dir), TimeToString(_dt)),
                  0,
                  _from,
                  _price,
                  _to,
                  _price,
                  clr,
                  STYLE_DASH,
                  2, 
                  false,
                  false,
                  false,
                  false,
                  false,
                  0);    
  // Left arrow               
  TextCreate(0,               // ID графика 
             StringFormat("%s|LEV_START|%s|%s", Logger.Name, PositionTypeToString(_dir), TimeToString(_dt)),
             0,             // номер подокна 
             _from,            // время точки привязки
             _price,           // цена точки привязки
             "è",              // сам текст 
             "Wingdings",             // шрифт 
             10,             // размер шрифта 
             clr,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью 
  
  // Right arrow
  TextCreate(0,               // ID графика 
             StringFormat("%s|LEV_FINISH|%s|%s", Logger.Name, PositionTypeToString(_dir), TimeToString(_dt)),
             0,             // номер подокна 
             _to,            // время точки привязки
             _price,           // цена точки привязки
             "ç",              // сам текст 
             "Wingdings",             // шрифт 
             10,             // размер шрифта 
             clr,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                                
             
  // TP dash
  TextCreate(0,               // ID графика 
             StringFormat("%s|LEV_TP|%s|%s", Logger.Name, PositionTypeToString(_dir), TimeToString(_dt)),
             0,             // номер подокна 
             _from,            // время точки привязки
             _tp,           // цена точки привязки
             "—",              // сам текст 
             "Arial",             // шрифт 
             10,             // размер шрифта 
             clr,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);      
  // SL cross
  TextCreate(0,               // ID графика 
             StringFormat("%s|LEV_SL|%s|%s", Logger.Name, PositionTypeToString(_dir), TimeToString(_dt)),
             0,             // номер подокна 
             _from,            // время точки привязки
             _sl,           // цена точки привязки
             "X",              // сам текст 
             "Arial",             // шрифт 
             10,             // размер шрифта 
             clr,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                       
}
