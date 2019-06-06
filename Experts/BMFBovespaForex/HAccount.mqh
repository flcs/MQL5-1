//+------------------------------------------------------------------+
//|                                                     HAccount.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários para obter informações da conta."

//+------------------------------------------------------------------+
//| Classe CAccount - responsável por extrair informações sobre a    |
//| conta que o EA está operando.                                    |
//+------------------------------------------------------------------+
class CAccount {
      
   public:
      void CAccount() {};            // Construtor
      void ~CAccount() {};           // Construtor
      double calcularLucroPosicoesAbertas(void);
      double calcularPrejuizoPosicoesAbertas(void);
};

//+------------------------------------------------------------------+
//| Método que calcula o lucro obtido com todas as posições          |
//| lucrativas abertas para todos os ativos.                         |
//+------------------------------------------------------------------+
double CAccount::calcularLucroPosicoesAbertas(void) {
   
   double lucro = 0;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetDouble(POSITION_PROFIT) > 0) {
         lucro += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   return lucro;  
}

//+------------------------------------------------------------------+
//| Método que calcula o prejuízo obtido com todas as posições       |
//| perdedoras abertas para todos os ativos.                         |
//+------------------------------------------------------------------+
double CAccount::calcularPrejuizoPosicoesAbertas(void) {

   double prejuizo = 0;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetDouble(POSITION_PROFIT) <= 0) {
         prejuizo += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   return prejuizo;
}