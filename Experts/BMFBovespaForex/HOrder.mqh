//+------------------------------------------------------------------+
//|                                                       HOrder.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários para negociação com robôs."

//+------------------------------------------------------------------+
//| Classe COrder - responsável por realizar envio de ordens.        |
//+------------------------------------------------------------------+
class COrder {
      
   public:
      void COrder() {};            // Construtor
      void ~COrder() {};           // Construtor
      ENUM_ORDER_TYPE_FILLING obterTipoPreenchimentoOrdem();
};

//+------------------------------------------------------------------+
//| Retorna o tipo de preenchimento de ordem permitida pelo símbolo  |
//| (ativo) selecionado.                                             |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING COrder::obterTipoPreenchimentoOrdem(void) {

   switch( (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)) {
      case SYMBOL_FILLING_FOK: return ORDER_FILLING_FOK;
      case SYMBOL_FILLING_IOC: return ORDER_FILLING_IOC;
      default: return ORDER_FILLING_RETURN;
   }
}