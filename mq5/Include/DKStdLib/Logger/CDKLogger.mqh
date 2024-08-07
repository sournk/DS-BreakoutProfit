//+------------------------------------------------------------------+
//|                                                    CDKLogger.mqh |
//|                                                  Denis Kislitsyn |
//|                                               http:/kislitsyn.me |
//|
//| 2024-06-26: 
//|   [*] Class is renamed to CDKLogger
//|   [+] Init(const string _name, const LogLevel _level, const string _format = NULL)
//| 2024-06-20: 
//|   [+] Assert method with same message for True and False
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "http:/kislitsyn.me"
#property version   "0.0.3"


enum LogLevel {
  DEBUG=10,
  INFO=20,
  WARN=30,
  ERROR=40,
  CRITICAL=50,
  NO=100,
};
   
class CDKLogger {
  public:
    string   Name;
    LogLevel Level;
    string   Format;  // Avaliable patterns: %YYYY%, %MM%, %DD%, %hh%, %mm%, %ss%, %name%, %level%, %message%

    CDKLogger(void) {Level = LogLevel(INFO);};
    CDKLogger(string LoggerName, LogLevel MessageLevel = LogLevel(INFO)) {
      Name = LoggerName;
      Level = LogLevel(INFO);
    }
    
    void Log(string MessageTest, LogLevel MessageLevel = LogLevel(INFO), const bool ToAlert = false) {
      if (MessageLevel >= Level) 
        if (Format != "") {         
          string message = Format;
          datetime dt_local = TimeLocal();
          string date = TimeToString(dt_local, TIME_DATE);
          string sec = TimeToString(dt_local, TIME_SECONDS);
          
          
          StringReplace(message, "%YYYY%", StringSubstr(date, 0, 4));
          StringReplace(message, "%MM%", StringSubstr(date, 5, 2));
          StringReplace(message, "%DD%", StringSubstr(date, 8, 2));
          
          StringReplace(message, "%hh%", StringSubstr(sec, 0, 2));
          StringReplace(message, "%mm%", StringSubstr(sec, 3, 2));
          StringReplace(message, "%ss%", StringSubstr(sec, 6, 2));
          
          StringReplace(message, "%level%", EnumToString(MessageLevel));
          StringReplace(message, "%name%", Name);
          StringReplace(message, "%message%", MessageTest);
          
          Print(message);
          if (ToAlert) Alert(message);
        }
        else {
          string message = StringFormat("[%s]:%s:[%s] %s",
                                        TimeToString(TimeLocal()),
                                        Name,
                                        EnumToString(MessageLevel), 
                                        MessageTest);
          Print(message); 
          if (ToAlert) Alert(message);
        }
    }; 
  
    void Debug(string MessageTest, const bool ToAlert = false) {
      Log(MessageTest, LogLevel(DEBUG), ToAlert);
    };           

    void Info(string MessageTest, const bool ToAlert = false) {
      Log(MessageTest, LogLevel(INFO), ToAlert);
    }; 
    
    void Warn(string MessageTest, const bool ToAlert = false) {
      Log(MessageTest, LogLevel(WARN), ToAlert);
    };         
    
    void Error(string MessageTest, const bool ToAlert = false) {
      Log(MessageTest, LogLevel(ERROR), ToAlert);
    };         
    
    void Critical(string MessageTest, const bool ToAlert = false) { 
      Log(MessageTest, LogLevel(CRITICAL), ToAlert);
    };  
    
    void Assert(const bool aCondition, 
                const string aTrueMessage, const LogLevel aTrueLevel = INFO, 
                const string aFalseMessage = "", const LogLevel aFalseLevel = ERROR,
                const bool ToAlert = false) {
      if (!aCondition) {
        if (aFalseMessage != "")
          Log(aFalseMessage, aFalseLevel, ToAlert);
      }
      else 
        Log(aTrueMessage, aTrueLevel, ToAlert);
    }       
    
    void Assert(const bool aCondition, 
                const string aMessage, 
                const LogLevel aTrueLevel = INFO, 
                const LogLevel aFalseLevel = ERROR,
                const bool ToAlert = false) {
      Assert(aCondition, aMessage, aTrueLevel, aMessage, aFalseLevel, ToAlert);
    }   
    
    void Init(const string _name, const LogLevel _level, const string _format = NULL) {
      Name = _name;
      Level = _level;
      if (_format == NULL) Format = "%name%:[%level%] %message%";
      else Format = _format;
    }               
};