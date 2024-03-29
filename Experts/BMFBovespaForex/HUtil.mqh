//+------------------------------------------------------------------+
//|                                                        HUtil.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários de uso geral."

//--- Enumerações
enum ENUM_TIPO_MENSAGEM {
   CONSOLE = 0,
   GRAFICO = 1,
   TERMINAL = 2,
   PUSH = 3,
   EMAIL = 4
};

//+------------------------------------------------------------------+
//| Classe CUtil - responsável por prover os métodos utilitários.    |
//+------------------------------------------------------------------+
class CUtil {
      
   public:
      void CUtil() {};            // Construtor
      void ~CUtil() {};           // Construtor
      void enviarMensagem(ENUM_TIPO_MENSAGEM tipoMensagem, string mensagem);
      void mostrarMensagem(string mensagem);
      void enviarMensagemUsuario(string mensagem);
      double multiploDe100(double valor);
};

//+------------------------------------------------------------------+
//| Método que envia mensagens para a saída correspondente. O        |
//| parâmetro tipoMensagem define qual será o meio que a mensagem    |
//| será mostrada (console, terminal, gráfico, e-mail ou push).      |
//+------------------------------------------------------------------+
void CUtil::enviarMensagem(ENUM_TIPO_MENSAGEM tipoMensagem, string mensagem) {

   switch (tipoMensagem) {
      case GRAFICO :
         Comment(mensagem);      
         break;
      case TERMINAL:
         Alert(mensagem);
         break;
      case PUSH:
         if (!SendNotification(mensagem)) {
            //--- Imprime informações sobre o erro no console
            Print("Falha ao enviar a mensagem via push! Erro ", GetLastError());
         }
         break;
      case EMAIL: {
            string assunto = "Notificação";
            if (!SendMail(assunto, mensagem)) {
               //--- Imprime informações sobre o erro no console
               Print("Falha ao enviar a mensagem via e-mail! Erro ", GetLastError());
            }
            break;
         }
      default : Print(mensagem); // A saída padrão é o console
   }

}

void CUtil::mostrarMensagem(string mensagem) {
   if (MQL5InfoInteger(MQL5_DEBUGGING) || MQL5InfoInteger(MQL5_DEBUG) || MQL5InfoInteger(MQL5_TESTER) || MQL5InfoInteger(MQL5_TESTING)) {
      Print(mensagem);
   }
}

void CUtil::enviarMensagemUsuario(string mensagem) {
   if (MQL5InfoInteger(MQL5_DEBUGGING) || MQL5InfoInteger(MQL5_DEBUG) || MQL5InfoInteger(MQL5_TESTER) || MQL5InfoInteger(MQL5_TESTING)) {
      this.enviarMensagem(GRAFICO, mensagem);
   } else {
      this.enviarMensagem(PUSH, mensagem);
   }
}

//+------------------------------------------------------------------+
//| Calcula e retorno o múltiplo de 100 mais próximo do valor        |
//| fornecido.                                                       |
//+------------------------------------------------------------------+
double CUtil::multiploDe100(double valor) {

   double resultado = 0;

   do {
      resultado += 100;
   } while(resultado < MathAbs(valor));

   return(resultado);
}
//+------------------------------------------------------------------+