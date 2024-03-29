//+------------------------------------------------------------------+
//|                                                       HOrder.mqh |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property description "Classe com métodos utilitários para negociação com robôs."

//--- Inclusão de arquivos
#include "HMoney.mqh"

//--- Declaração de classes
CMoney cMoney; // Classe com métodos utilitários para gerenciamento financeiro da conta

//+------------------------------------------------------------------+
//| Classe COrder - responsável por realizar envio de ordens.        |
//+------------------------------------------------------------------+
class COrder {
      
   public:
      void COrder() {};            // Construtor
      void ~COrder() {};           // Construtor
      ENUM_ORDER_TYPE_FILLING obterTipoPreenchimentoOrdem();
      bool possuiMargemParaAbrirNovaPosicao(double tamanhoContrato, string simbolo, ENUM_POSITION_TYPE tipoPosicao);
      bool enviaOrdem(ENUM_ORDER_TYPE typeOrder,
                 ENUM_TRADE_REQUEST_ACTIONS typeAction,
                 double price,
                 double volume,
                 double stop,
                 double profit,
                 ulong deviation,
                 ulong positionTicket,
                 datetime expiration);
      bool fecharPosicao(ulong positionTicket);
      bool existePosicoesAbertas(ENUM_POSITION_TYPE tipoPosicao);
      void fecharTodasPosicoesAbertas(string simbolo);
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

//+------------------------------------------------------------------+
//| Verifica se existe margem disponível para abertura de novas      |
//| posições para o símbolo selecionado. Retorna true caso tenha     |
//| margem disponível para efetuar a abertura com o tamanho de       |
//| contrato selecionado.                                            |
//+------------------------------------------------------------------+
bool COrder::possuiMargemParaAbrirNovaPosicao(double tamanhoContrato, string simbolo, ENUM_POSITION_TYPE tipoPosicao) {

   if (cAccount.obterMargemLivre() > cAccount.obterMargemNecessariaParaNovaPosicao(tamanhoContrato, tipoPosicao)) {
      return(true);
   }
   
   return(false);

}

//+------------------------------------------------------------------+ 
//|  Efetua uma operação de negociação a mercado                     |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+
bool COrder::enviaOrdem(ENUM_ORDER_TYPE typeOrder,
                 ENUM_TRADE_REQUEST_ACTIONS typeAction,
                 double price,
                 double volume,
                 double stop,
                 double profit,
                 ulong deviation=100,
                 ulong positionTicket=0,
                 datetime expiration = 0) {

   //--- Declaração e inicialização das estruturas
   MqlTradeRequest tradeRequest; // Envia as requisições de negociação
   MqlTradeResult tradeResult; // Receba o resultado das requisições de negociação
   ZeroMemory(tradeRequest); // Inicializa a estrutura
   ZeroMemory(tradeResult); // Inicializa a estrutura
   
   //--- Popula os campos da estrutura tradeRequest
   tradeRequest.action = typeAction; // Tipo de execução da ordem
   tradeRequest.price = NormalizeDouble(price, _Digits); // Preço da ordem
   tradeRequest.sl = NormalizeDouble(stop, _Digits); // Stop loss da ordem
   tradeRequest.tp = NormalizeDouble(profit, _Digits); // Take profit da ordem
   tradeRequest.symbol = _Symbol; // Símbolo
   tradeRequest.volume = volume; // Volume a ser negociado
   tradeRequest.type = typeOrder; // Tipo de ordem
   tradeRequest.magic = magicNumber; // Número mágico do EA
   tradeRequest.type_filling = cOrder.obterTipoPreenchimentoOrdem(); // Tipo de execução da ordem
   tradeRequest.deviation = deviation; // Desvio permitido em relação ao preço
   tradeRequest.position = positionTicket; // Ticket da posição
   tradeRequest.expiration = expiration; // Expiração da ordem
   
   //--- Envia a ordem
   if(!OrderSend(tradeRequest, tradeResult)) {
      //-- Exibimos as informações sobre a falha
      Alert("Não foi possível enviar a ordem! Erro ",GetLastError());
      PrintFormat("Envio de ordem %s %s %.2f a %.5f, erro %d", tradeRequest.symbol, EnumToString(typeOrder), volume, tradeRequest.price, GetLastError());
      return(false);
   }
   
   //-- Exibimos as informações sobre a ordem bem-sucedida
   Alert("Uma nova ordem foi enviada com sucesso! Ticket #", tradeResult.order);
   PrintFormat("Código %u, negociação %I64u, ticket #%I64u", tradeResult.retcode, tradeResult.deal, tradeResult.order);
   
   //--- Limpa as variáveis de instâncias de CMoney
   cMoney.limparVariaveis();
   
   return(true);   
}

bool COrder::fecharPosicao(ulong positionTicket) {

   //--- Seleciona a posição a partir do ticket informado
   if (PositionSelectByTicket(positionTicket)) {
   
      //--- Ajusta o preço nos casos do tick vier com um valor inválido
      double preco = 0;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) {
         preco = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      } else {
         preco = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
   
      if ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING) {
         //--- Obtém o tamanho do tick
         double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      
         // Diminui o resto da divisão do preço com o tick size para igualar ao
         // último múltiplo do valor de tick size
         if (fmod(preco, tickSize) != 0) {
            preco = preco - fmod(preco, tickSize);
         }
      }
   
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) {
         return(this.enviaOrdem(ORDER_TYPE_SELL, TRADE_ACTION_DEAL, preco, PositionGetDouble(POSITION_VOLUME), 0, 0, 100, positionTicket));
      } else {
         return(this.enviaOrdem(ORDER_TYPE_BUY, TRADE_ACTION_DEAL, preco, PositionGetDouble(POSITION_VOLUME), 0, 0, 100, positionTicket));
      }
   }

   return(false);
}     

//+------------------------------------------------------------------+ 
//|  Verifica se existe posição aberta para o símbolo atualmente     |
//|  selecionado. Retorna false caso não tenha nenhuma posição aberta|
//|  para o tipo de posição informado.                               |
//+------------------------------------------------------------------+
bool COrder::existePosicoesAbertas(ENUM_POSITION_TYPE tipoPosicao) {
   int contadorCompra = 0;
   int contadorVenda = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         if ( ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)) == POSITION_TYPE_BUY ) {
            contadorCompra++;
         } else {
            contadorVenda++;
         }
      }
   }
   
   if (tipoPosicao == POSITION_TYPE_BUY && contadorCompra > 0) {
      return(true);
   }
   if (tipoPosicao == POSITION_TYPE_SELL && contadorVenda > 0) {
      return(true);
   }
   
   return(false);
}

//+------------------------------------------------------------------+
//| Fecha todas as posições atualmente abertas para o símbolo        |
//| informado.                                                       |
//+------------------------------------------------------------------+
void COrder::fecharTodasPosicoesAbertas(string simbolo) {
   //-- Fecha todas as posições abertas
   if (PositionsTotal() > 0) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == simbolo) {
            cOrder.fecharPosicao(PositionGetTicket(i));
         }
      }
   }
}
//+------------------------------------------------------------------+