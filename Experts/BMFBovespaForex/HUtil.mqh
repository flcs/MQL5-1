//+------------------------------------------------------------------+
//|                                                        HUtil.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários de uso geral."

//+------------------------------------------------------------------+
//| Classe CUtil - responsável por prover os métodos utilitários.    |
//+------------------------------------------------------------------+
class CUtil {
      
   public:
      void CUtil() {};            // Construtor
      void ~CUtil() {};           // Construtor
      void mensagemConsole(string mensagem);
      void mensagemGrafico(string mensagem);
      void mensagemTerminal(string mensagem);
      void mensagemPush(string mensagem);
};

//+------------------------------------------------------------------+
//| Método que imprime uma mensagem no console. As mensagens são     |
//| mostradas unicamente quando o EA está em modo debugger ou        |
//| testing.
//+------------------------------------------------------------------+

void CUtil::mensagemConsole(string mensagem) {
   if (MQL5InfoInteger(MQL5_DEBUGGING) || MQL5InfoInteger(MQL5_DEBUG) || MQL5InfoInteger(MQL5_TESTER) || MQL5InfoInteger(MQL5_TESTING)) {
      Print(mensagem);
   }
}

//+------------------------------------------------------------------+
//| Método que imprime uma mensagem no gráfico atual.                |
//+------------------------------------------------------------------+

void CUtil::mensagemGrafico(string mensagem) {
   Comment(mensagem);
}

//+------------------------------------------------------------------+
//| Método que envia um alerta para o terminal do usuário.           |
//+------------------------------------------------------------------+

void CUtil::mensagemTerminal(string mensagem) {
   Alert(mensagem);
}

//+------------------------------------------------------------------+
//| Método que envia uma notificação push para o usuário. Caso o     |
//| tenha o MetaTrader 5 no celular, e a opção de notificações push  |
//| esteja ativa no terminal, o usuário receberá pelo aplicação      |
//| informações adicionais sobre o estado da sua conta, o símbolo e  |
//| posições atualmente abertas.                                     |
//+------------------------------------------------------------------+
void CUtil::mensagemPush(string mensagem) {
   if (!SendNotification(mensagem)) {
      //--- Imprime informações sobre o erro no console
      Print("Falha ao enviar a mensagem via push! Erro ", GetLastError());
   }
}