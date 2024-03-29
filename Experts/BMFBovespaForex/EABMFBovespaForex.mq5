//+------------------------------------------------------------------+
//|                                            EABMFBovespaForex.mq5 |
//|                            Copyright ® 2019, Hércules S. S. José |
//|                        https://www.linkedin.com/in/herculeshssj/ |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2019, Hércules S. S. José"
#property link      "https://www.linkedin.com/in/herculeshssj/"
#property version   "1.14"

//--- Inclusão de arquivos
#include "Estrategias\HAdaptativos.mqh"
#include "Estrategias\HBillWilliams.mqh"
#include "Estrategias\HBMFBovespa.mqh"
#include "Estrategias\HCustomizados.mqh"
#include "Estrategias\HForex.mqh"
#include "Estrategias\HForexXAU.mqh"
#include "Estrategias\HJob.mqh"
#include "Estrategias\HMediasMoveis.mqh"
#include "Estrategias\HOsciladores.mqh"
#include "Estrategias\HTendencia.mqh"

//--- Variáveis estáticas
static int sinalAConfirmar = 0;
static ENUM_SYMBOL_CALC_MODE mercadoAOperar = SYMBOL_CALC_MODE_FOREX;
static int magicNumber = 19851024;
static int tickBarraTimer = 1; // Padrão, nova barra

//--- Parâmetros de entrada
input ESTRATEGIA_NEGOCIACAO estrategiaNegociacao = BMFBOVESPA_FOREX;

//+------------------------------------------------------------------+
//| Inicialização do Expert Advisor                                  |
//+------------------------------------------------------------------+
int OnInit() {
   
   //--- Exibe informações sobre a conta de negociação
   cAccount.relatorioInformacoesConta();
   
   /*** Carrega os parâmetros do EA do arquivo ***/
   
   //--- Nome do arquivo
   string filename = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "_" + _Symbol + ".bin";
   
   //--- Verifica se o arquivo existe
   if (FileIsExist(filename)) {
      //--- Abre o arquivo para leitura
      int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN);
      if (fileHandle != INVALID_HANDLE) {
         //--- Lê o magic number do EA
         magicNumber = FileReadInteger(fileHandle);
         
         //--- Fecha o arquivo
         FileClose(fileHandle);
      }      
      
   } else {
   
      //--- Gera o magic number do EA
      MathSrand(GetTickCount());
      magicNumber = MathRand() * 255;
      
      //--- Abre o arquivo para escrita
      int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN);
      if (fileHandle != INVALID_HANDLE) {
         // Grava o magic number do EA no arquivo
         FileWriteInteger(fileHandle, magicNumber);
         
         //--- Fecha o arquivo
         FileClose(fileHandle);
      }
   }
   
   //--- Cria um temporizador de 1 minuto
   EventSetTimer(60);
   
   //--- Inicializa a classe para stop móvel
   trailingStop.Init(_Symbol, _Period, magicNumber, true, true, false);
   
   //--- Carrega os parâmetros do indicador NRTR
   if (!trailingStop.setupParameters(40, 2)) {
      Alert("Erro na inicialização da classe de stop móvel! Saindo...");
      return(INIT_FAILED);
   }
   
   //--- Define o mercado que o EA está operando
   mercadoAOperar = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
   
   //--- Salva o valor do saldo atual da conta
   cMoney.saldoConta = AccountInfoDouble(ACCOUNT_BALANCE);
   
   //--- Inicia o stop móvel para as posições abertas
   trailingStop.on();
   
   //--- Inicializa os indicadores usados pela estratégia
   int inicializarEA = INIT_FAILED;
   
   switch (estrategiaNegociacao) {
      case BMFBOVESPA_FOREX : 
         tickBarraTimer = cBMFBovespaForex.onTickBarTimer();
         inicializarEA = cBMFBovespaForex.init();
         break;
      case MINICONTRATO_INDICE:
         tickBarraTimer = cMiniContratoIndice.onTickBarTimer();
         inicializarEA = cMiniContratoIndice.init();
         break;
      case CRUZAMENTO_MA_CURTA_AGIL : 
         tickBarraTimer = cCruzamentoMACurtaAgil.onTickBarTimer();
         inicializarEA = cCruzamentoMACurtaAgil.init();
         break;
      case CRUZAMENTO_MA_LONGA_CURTA :
         tickBarraTimer = cCruzamentoMALongaCurta.onTickBarTimer();
         inicializarEA = cCruzamentoMALongaCurta.init();
         break;
      case SINAL_ESTOCASTICO : 
         tickBarraTimer = cSinalEstocastico.onTickBarTimer();
         inicializarEA = cSinalEstocastico.init();
         break;
      case TENDENCIA_NRTR :
         tickBarraTimer = cTendenciaNRTR.onTickBarTimer();
         inicializarEA = cTendenciaNRTR.init();
         break;
      case DUNNIGAN : 
         tickBarraTimer = cDunnigan.onTickBarTimer();
         inicializarEA = cDunnigan.init();
         break;
      case DUNNIGAN_NRTR : 
         tickBarraTimer = cDunniganNRTR.onTickBarTimer();
         inicializarEA = cDunniganNRTR.init();
         break;
      case TENDENCIA_NRTRVOLATILE :
         tickBarraTimer = cTendenciaNRTRvolatile.onTickBarTimer();
         inicializarEA = cTendenciaNRTRvolatile.init();
         break;
      case SINAL_MACD : 
         tickBarraTimer = cSinalMACD.onTickBarTimer();
         inicializarEA = cSinalMACD.init();
         break;
      case ADX_MA : 
         tickBarraTimer = cAdxMA.onTickBarTimer();
         inicializarEA = cAdxMA.init();
         break;
      case SINAL_ATR : 
         tickBarraTimer = cSinalATR.onTickBarTimer();
         inicializarEA = cSinalATR.init();
         break;
      case SINAL_RSI : 
         tickBarraTimer = cSinalRSI.onTickBarTimer();
         inicializarEA = cSinalRSI.init();
         break;
      case SINAL_CCI : 
         tickBarraTimer = cSinalCCI.onTickBarTimer();
         inicializarEA = cSinalCCI.init();
         break;
      case SINAL_WPR : 
         tickBarraTimer = cSinalWPR.onTickBarTimer();
         inicializarEA = cSinalWPR.init();
         break;
      case SINAL_AMA : 
         tickBarraTimer = cSinalAMA.onTickBarTimer();
         inicializarEA = cSinalAMA.init();
         break;
      case FOREX_AMA : 
         tickBarraTimer = cForexAMA.onTickBarTimer();
         inicializarEA = cForexAMA.init();
         break;
      case FOREX_XAUEUR : 
         tickBarraTimer = cForexXAUEUR.onTickBarTimer();
         inicializarEA = cForexXAUEUR.init();
         break;
      case FOREX_XAUUSD : 
         tickBarraTimer = cForexXAUUSD.onTickBarTimer();
         inicializarEA = cForexXAUUSD.init();
         break;
      case FOREX_XAUAUD : 
         tickBarraTimer = cForexXAUAUD.onTickBarTimer();
         inicializarEA = cForexXAUAUD.init();
         break;
      case SINAL_AWESOME : 
         tickBarraTimer = cAwesome.onTickBarTimer();
         inicializarEA = cAwesome.init();
         break;
      case BOLLINGER_BANDS : 
         tickBarraTimer = cBollingerBands.onTickBarTimer();
         inicializarEA = cBollingerBands.init();
         break;
      case SINAL_ALLIGATOR : 
         tickBarraTimer = cAlligator.onTickBarTimer();
         inicializarEA = cAlligator.init();
         break;
      case ICHIMOKU_KINKO_HYO : 
         tickBarraTimer = cIchimoku.onTickBarTimer();
         inicializarEA = cIchimoku.init();
         break;
      case ADAPTIVE_CHANNEL_ADX : 
         tickBarraTimer = cAdaptiveChannelADX.onTickBarTimer();
         inicializarEA = cAdaptiveChannelADX.init();
         break;
      case PRICE_CHANNEL : 
         tickBarraTimer = cPriceChannel.onTickBarTimer();
         inicializarEA = cPriceChannel.init();
         break;
      case BUY_SELL_PRESSURE : 
         tickBarraTimer = cBuySellPressure.onTickBarTimer();
         inicializarEA = cBuySellPressure.init();
         break;
      case INSIDE_BAR : 
         tickBarraTimer = cInsideBar.onTickBarTimer();
         inicializarEA = cInsideBar.init();
         trailingStop.off();
         break;
      case FREELANCE_JOB :
         tickBarraTimer = cFreelanceJob.onTickBarTimer();
         inicializarEA = cFreelanceJob.init();
         trailingStop.off();
         break;
      case TABAJARA :
         tickBarraTimer = cTabajara.onTickBarTimer();
         inicializarEA = cTabajara.init();
         break;
      case CANAL_DESVIO_PADRAO :
         tickBarraTimer = cCanalDesvioPadrao.onTickBarTimer();
         inicializarEA = cCanalDesvioPadrao.init();
         break;
      case CANAL_DONCHIAN :
         tickBarraTimer = cCanalDonchian.onTickBarTimer();
         inicializarEA = cCanalDonchian.init();
         break;
      case SILVER_CHANNEL :
         tickBarraTimer = cSilverChannel.onTickBarTimer();
         inicializarEA = cSilverChannel.init();
         break;
      case PRICE_CHANNEL_GALLAHER :
         tickBarraTimer = cPriceChannelGallaher.onTickBarTimer();
         inicializarEA = cPriceChannelGallaher.init();
         break;
   }
   
   //--- Retorna o sinal de inicialização do EA   
   return(inicializarEA);
}

//+------------------------------------------------------------------+
//| Encerramento do Expert Advisor                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   //--- Libera os indicadores usado pela estratégia
   switch (estrategiaNegociacao) {
      case BMFBOVESPA_FOREX :
         cBMFBovespaForex.release();
         break;
      case MINICONTRATO_INDICE:
         cMiniContratoIndice.release();
         break;
      case CRUZAMENTO_MA_CURTA_AGIL : 
         cCruzamentoMACurtaAgil.release();
         break;
      case CRUZAMENTO_MA_LONGA_CURTA :
         cCruzamentoMALongaCurta.release();
         break;
      case SINAL_ESTOCASTICO :
         cSinalEstocastico.release();
         break;
      case TENDENCIA_NRTR : 
         cTendenciaNRTR.release();
         break;
      case DUNNIGAN : 
         cDunnigan.release();
         break;
      case DUNNIGAN_NRTR :
         cDunniganNRTR.release();
         break;
      case TENDENCIA_NRTRVOLATILE : 
         cTendenciaNRTRvolatile.release();
         break;
      case SINAL_MACD :
         cSinalMACD.release();
         break;
      case ADX_MA :
         cAdxMA.release();
         break;
      case SINAL_ATR :
         cSinalATR.release();
         break;
      case SINAL_RSI :
         cSinalRSI.release();
         break;
      case SINAL_CCI :
         cSinalCCI.release();
         break;
      case SINAL_WPR :
         cSinalWPR.release();
         break;
      case SINAL_AMA :
         cSinalAMA.release();
         break;
      case FOREX_AMA :
         cForexAMA.release();
         break;
      case FOREX_XAUEUR :
         cForexXAUEUR.release();
         break;
      case FOREX_XAUUSD :
         cForexXAUUSD.release();
         break;
      case FOREX_XAUAUD :
         cForexXAUAUD.release();
         break;
      case SINAL_AWESOME :
         cAwesome.release();
         break;
      case BOLLINGER_BANDS :
         cBollingerBands.release();
         break;
      case SINAL_ALLIGATOR :
         cAlligator.release();
         break;
      case ICHIMOKU_KINKO_HYO :
         cIchimoku.release();
         break;
      case ADAPTIVE_CHANNEL_ADX :
         cAdaptiveChannelADX.release();
         break;
      case PRICE_CHANNEL :
         cPriceChannel.release();
         break;
      case BUY_SELL_PRESSURE :
         cBuySellPressure.release();
         break;
      case INSIDE_BAR :
         cInsideBar.release();
         break;
      case FREELANCE_JOB :
         cFreelanceJob.release();
         break;
      case TABAJARA :
         cTabajara.release();
         break;
      case CANAL_DESVIO_PADRAO : cCanalDesvioPadrao.release(); break;
      case CANAL_DONCHIAN : cCanalDonchian.release(); break;
      case SILVER_CHANNEL : cSilverChannel.release(); break;
      case PRICE_CHANNEL_GALLAHER : cPriceChannelGallaher.release(); break;
   }

   //--- Encerra o stop móvel
   trailingStop.Deinit();
   
   //--- Destrói o temporizador
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Método que recebe os ticks vindo do gráfico                      |
//+------------------------------------------------------------------+
void OnTick() {
   
    //--- Checa se as posições precisam ser encerradas após a chegada de um novo tick
    sinalSaidaNegociacao(0);
   
   //--- Verifica se a estratégia aciona os sinais de negociação após uma
   //--- nova barra no gráfico
   if (temNovaBarra()) {
   
      //--- Checa se as posições precisam ser encerradas
      sinalSaidaNegociacao(1);
   
      if (tickBarraTimer == 1) {
         //--- Verifica se possui sinal de negociação a confirmar
         sinalAConfirmar = sinalNegociacao();
         if (sinalAConfirmar != 0) {
            confirmarSinal();         
         }
      }
      
      //--- Notifica ao usuário de algum acontecimento, de acordo com o definido na
      //--- estratégia de negociação escolhida. A notificação é disparada com a chegada
      //--- de uma nova barra
      notificarUsuario(1);
   }
      
   //--- Verifica se a estratégia aciona os sinais de negociação após um novo tick
   if (tickBarraTimer == 0) {
   
      //--- Verifica se possui sinal de negociação a confirmar
      sinalAConfirmar = sinalNegociacao();
      if (sinalAConfirmar != 0) {
         confirmarSinal();         
      }
      
   }
   
   //--- Notifica ao usuário de algum acontecimento, de acordo com o definido na
   //--- estratégia de negociação escolhida. A notificação é disparada com a chegada
   //--- de um novo tick
   notificarUsuario(0);   
}

//+------------------------------------------------------------------+
//| Conjuntos de rotinas padronizadas a serem executadas a cada      |
//| minuto (60 segundos).                                            |
//+------------------------------------------------------------------+
void OnTimer() {

   //--- Verifica se o mercado ainda está aberto para poder realizar o 
   //--- trailing stop das posições abertas
   
   //--- Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);
   
   if (mercadoAberto(horaAtual)) {
   
      //--- Atualiza os dados do stop móvel
      trailingStop.refresh();
      
      //--- Realiza o stop móvel das posições abertas
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            trailingStop.doStopLoss(PositionGetTicket(i));
         }         
      }
   
   }

   //--- Checa se as posições precisam ser encerradas
   sinalSaidaNegociacao(9);
   
   //--- Verifica se a estratégia aciona os sinais de negociação após transcorrer
   //--- o tempo no timer
   if (tickBarraTimer == 9) {
   
      //--- Verifica se possui sinal de negociação a confirmar
      sinalAConfirmar = sinalNegociacao();
      if (sinalAConfirmar != 0) {
         confirmarSinal();         
      }
            
   }
   
   //--- Notifica ao usuário de algum acontecimento, de acordo com o definido na
   //--- estratégia de negociação escolhida. A notificação é disparada com a
   //--- passagem de um novo ciclo do timer.
   notificarUsuario(9);
   
}

//+------------------------------------------------------------------+
//|  Função responsável por informar se o momento é de abrir uma     |
//|  posição de compra ou venda.                                     |
//|                                                                  |
//|  Valor negativo - Abre uma posição de venda                      |
//|  Valor positivo - Abre uma posição de compra                     |
//|  Valor zero (0) - Nenhum posição é aberta                        |
//+------------------------------------------------------------------+
int sinalNegociacao() {

   //--- Obtém a hora atual
   MqlDateTime horaAtual;
   TimeCurrent(horaAtual);
   
   //--- Verifica se o mercado está aberto para negociações
   if (mercadoAberto(horaAtual)) {
   
      switch (estrategiaNegociacao) {
         case BMFBOVESPA_FOREX :
            return(cBMFBovespaForex.sinalNegociacao()); break;
         case MINICONTRATO_INDICE:
            return(cMiniContratoIndice.sinalNegociacao()); break;
         case CRUZAMENTO_MA_CURTA_AGIL : 
            return(cCruzamentoMACurtaAgil.sinalNegociacao()); break;
         case CRUZAMENTO_MA_LONGA_CURTA :
            return(cCruzamentoMALongaCurta.sinalNegociacao()); break;
         case SINAL_ESTOCASTICO :
            return(cSinalEstocastico.sinalNegociacao()); break;
         case TENDENCIA_NRTR :
            return(cTendenciaNRTR.sinalNegociacao()); break;
         case DUNNIGAN :
            return(cDunnigan.sinalNegociacao()); break;
         case DUNNIGAN_NRTR :
            return(cDunniganNRTR.sinalNegociacao()); break;
         case TENDENCIA_NRTRVOLATILE :
            return(cTendenciaNRTRvolatile.sinalNegociacao()); break;
         case SINAL_MACD :
            return(cSinalMACD.sinalNegociacao()); break;
         case ADX_MA :
            return(cAdxMA.sinalNegociacao()); break;
         case SINAL_ATR :
            return(cSinalATR.sinalNegociacao()); break;
         case SINAL_RSI :
            return(cSinalRSI.sinalNegociacao()); break;
         case SINAL_CCI :
            return(cSinalCCI.sinalNegociacao()); break;
         case SINAL_WPR :
            return(cSinalWPR.sinalNegociacao()); break;
         case SINAL_AMA :
            return(cSinalAMA.sinalNegociacao()); break;
         case FOREX_AMA :
            return(cForexAMA.sinalNegociacao()); break;
         case FOREX_XAUEUR :
            return(cForexXAUEUR.sinalNegociacao()); break;
         case FOREX_XAUUSD :
            return(cForexXAUUSD.sinalNegociacao()); break;
         case FOREX_XAUAUD :
            return(cForexXAUAUD.sinalNegociacao()); break;
         case SINAL_AWESOME :
            return(cAwesome.sinalNegociacao()); break;
         case BOLLINGER_BANDS :
            return(cBollingerBands.sinalNegociacao()); break;
         case SINAL_ALLIGATOR :
            return(cAlligator.sinalNegociacao()); break;
         case ICHIMOKU_KINKO_HYO :
            return(cIchimoku.sinalNegociacao()); break;
         case ADAPTIVE_CHANNEL_ADX :
            return(cAdaptiveChannelADX.sinalNegociacao()); break;
         case PRICE_CHANNEL :
            return(cPriceChannel.sinalNegociacao()); break;
         case BUY_SELL_PRESSURE :
            return(cBuySellPressure.sinalNegociacao()); break;
         case INSIDE_BAR :
            return(cInsideBar.sinalNegociacao()); break;
         case FREELANCE_JOB :
            return(cFreelanceJob.sinalNegociacao()); break;
         case TABAJARA : return(cTabajara.sinalNegociacao()); break;
         case CANAL_DESVIO_PADRAO : return(cCanalDesvioPadrao.sinalNegociacao()); break;
         case CANAL_DONCHIAN : return(cCanalDonchian.sinalNegociacao()); break;
         case SILVER_CHANNEL : return(cSilverChannel.sinalNegociacao()); break;
         case PRICE_CHANNEL_GALLAHER : return(cPriceChannelGallaher.sinalNegociacao()); break;
      }
   
   }
   
   return(0);
}

//+------------------------------------------------------------------+
//|  Função responsável por verificar se é o momento de encerrar a   |
//|  posição de compra ou venda aberta. Caso a estratégia retorna o  |
//|  valor 0 significa que as posições abertas para o símbolo atual  |
//|  devem ser encerradas.                                           |
//+------------------------------------------------------------------+
void sinalSaidaNegociacao(int chamadaSaida) {

   //--- O padrão é manter as posições abertas
   int sinal = -1;

   switch (estrategiaNegociacao) {
      case BMFBOVESPA_FOREX :
         sinal = cBMFBovespaForex.sinalSaidaNegociacao(chamadaSaida); break;
      case MINICONTRATO_INDICE:
         sinal = cMiniContratoIndice.sinalSaidaNegociacao(chamadaSaida); break;
      case CRUZAMENTO_MA_CURTA_AGIL : 
         sinal = cCruzamentoMACurtaAgil.sinalSaidaNegociacao(chamadaSaida); break;
      case CRUZAMENTO_MA_LONGA_CURTA :
         sinal = cCruzamentoMALongaCurta.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_ESTOCASTICO :
         sinal = cSinalEstocastico.sinalSaidaNegociacao(chamadaSaida); break;
      case TENDENCIA_NRTR :
         sinal = cTendenciaNRTR.sinalSaidaNegociacao(chamadaSaida); break;
      case DUNNIGAN :
         sinal = cDunnigan.sinalSaidaNegociacao(chamadaSaida); break;
      case DUNNIGAN_NRTR :
         sinal = cDunniganNRTR.sinalSaidaNegociacao(chamadaSaida); break;
      case TENDENCIA_NRTRVOLATILE :
         sinal = cTendenciaNRTRvolatile.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_MACD :
         sinal = cSinalMACD.sinalSaidaNegociacao(chamadaSaida); break;
      case ADX_MA :
         sinal = cAdxMA.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_ATR :
         sinal = cSinalATR.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_RSI :
         sinal = cSinalRSI.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_CCI :
         sinal = cSinalCCI.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_WPR :
         sinal = cSinalWPR.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_AMA :
         sinal = cSinalAMA.sinalSaidaNegociacao(chamadaSaida); break;
      case FOREX_AMA :
         sinal = cForexAMA.sinalSaidaNegociacao(chamadaSaida); break;
      case FOREX_XAUEUR :
         sinal = cForexXAUEUR.sinalSaidaNegociacao(chamadaSaida); break;
      case FOREX_XAUUSD :
         sinal = cForexXAUEUR.sinalSaidaNegociacao(chamadaSaida); break;
      case FOREX_XAUAUD :
         sinal = cForexXAUAUD.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_AWESOME :
         sinal = cAwesome.sinalSaidaNegociacao(chamadaSaida); break;
      case BOLLINGER_BANDS :
         sinal = cBollingerBands.sinalSaidaNegociacao(chamadaSaida); break;
      case SINAL_ALLIGATOR :
         sinal = cAlligator.sinalSaidaNegociacao(chamadaSaida); break;
      case ICHIMOKU_KINKO_HYO :
         sinal = cIchimoku.sinalSaidaNegociacao(chamadaSaida); break;
      case ADAPTIVE_CHANNEL_ADX :
         sinal = cAdaptiveChannelADX.sinalSaidaNegociacao(chamadaSaida); break;
      case PRICE_CHANNEL :
         sinal = cPriceChannel.sinalSaidaNegociacao(chamadaSaida); break;
      case BUY_SELL_PRESSURE :
         sinal = cBuySellPressure.sinalSaidaNegociacao(chamadaSaida); break;
      case INSIDE_BAR :
         sinal = cInsideBar.sinalSaidaNegociacao(chamadaSaida); break;
      case FREELANCE_JOB :
         sinal = cFreelanceJob.sinalSaidaNegociacao(chamadaSaida); break;
      case TABAJARA : sinal = cTabajara.sinalSaidaNegociacao(chamadaSaida); break;
      case CANAL_DESVIO_PADRAO : sinal = cCanalDesvioPadrao.sinalSaidaNegociacao(chamadaSaida); break;
      case CANAL_DONCHIAN : sinal = cCanalDonchian.sinalSaidaNegociacao(chamadaSaida); break;
      case SILVER_CHANNEL : sinal = cSilverChannel.sinalSaidaNegociacao(chamadaSaida); break;
      case PRICE_CHANNEL_GALLAHER : sinal = cPriceChannelGallaher.sinalSaidaNegociacao(chamadaSaida); break;
   }
   
   //--- Verifica o sinal de saída da negociação aberta
   if (sinal == 0) {
      //--- Encerra as posições para o símbolo atual
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            string mensagem = "";
            
            //--- Constrói a mensagem
            if (PositionGetDouble(POSITION_PROFIT) >= 0) {
               mensagem = "Ticket #" + IntegerToString(PositionGetTicket(i)) 
               + " do símbolo " + _Symbol + " fechado com o lucro de " 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT));
            } else {
               mensagem = "Ticket #" + IntegerToString(PositionGetTicket(i)) 
               + " do símbolo " + _Symbol + " fechado com o prejuízo de " 
               + DoubleToString(PositionGetDouble(POSITION_PROFIT));
            }
            
            //--- Envia a ordem para encerrar a posição
            cOrder.fecharPosicao(PositionGetTicket(i));
            
            //--- Envia a notificação para o usuário            
            cUtil.enviarMensagemUsuario(mensagem);
            
         }
      }
   }
   
   //--- Verifica o saldo atual da conta e atualiza o atributo correspondente
   //--- em cMoney para poder realizar a proteção do novo saldo
   if ((AccountInfoDouble(ACCOUNT_BALANCE) - cMoney.saldoConta) > 100) {
      //--- Incrementa o saldo da conta em cMoney
      cMoney.saldoConta += 100;
   }
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar se o momento é de abrir uma    |
//|  posição de compra ou venda. Esta função é chamada sempre que se |
//|  obter a confirmação do sinal a partir de outro indicador ou     |
//|  outra forma de cálculo.                                         |
//|                                                                  |
//|  -1 - Confirma a abertura da posição de venda                    |
//|  +1 - Confirma a abertura da posição de compra                   |
//|   0 - Informa que nenhuma posição deve ser aberta                |
//+------------------------------------------------------------------+
int sinalConfirmacao() {
   
   switch (estrategiaNegociacao) {
      case BMFBOVESPA_FOREX :
         return(cBMFBovespaForex.sinalConfirmacao(sinalAConfirmar)); break;
      case MINICONTRATO_INDICE:
         return(cMiniContratoIndice.sinalConfirmacao(sinalAConfirmar)); break;
      case CRUZAMENTO_MA_CURTA_AGIL : 
         return(cCruzamentoMACurtaAgil.sinalConfirmacao(sinalAConfirmar)); break;
      case CRUZAMENTO_MA_LONGA_CURTA :
         return(cCruzamentoMALongaCurta.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_ESTOCASTICO : 
         return(cSinalEstocastico.sinalConfirmacao(sinalAConfirmar)); break;
      case TENDENCIA_NRTR :
         return(cTendenciaNRTR.sinalConfirmacao(sinalAConfirmar)); break;
      case DUNNIGAN :
         return(cDunnigan.sinalConfirmacao(sinalAConfirmar)); break;
      case DUNNIGAN_NRTR :
         return(cDunniganNRTR.sinalConfirmacao(sinalAConfirmar)); break;
      case TENDENCIA_NRTRVOLATILE :
         return(cTendenciaNRTRvolatile.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_MACD : 
         return(cSinalMACD.sinalConfirmacao(sinalAConfirmar)); break;
      case ADX_MA : 
         return(cAdxMA.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_ATR :
         return(cSinalATR.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_RSI :
         return(cSinalRSI.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_CCI :
         return(cSinalRSI.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_WPR :
         return(cSinalWPR.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_AMA :
         return(cSinalAMA.sinalConfirmacao(sinalAConfirmar)); break;
      case FOREX_AMA :
         return(cForexAMA.sinalConfirmacao(sinalAConfirmar)); break;
      case FOREX_XAUEUR :
         return(cForexXAUEUR.sinalConfirmacao(sinalAConfirmar)); break;
      case FOREX_XAUUSD :
         return(cForexXAUUSD.sinalConfirmacao(sinalAConfirmar)); break;
      case FOREX_XAUAUD :
         return(cForexXAUAUD.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_AWESOME :
         return(cAwesome.sinalConfirmacao(sinalAConfirmar)); break;
      case BOLLINGER_BANDS :
         return(cBollingerBands.sinalConfirmacao(sinalAConfirmar)); break;
      case SINAL_ALLIGATOR :
         return(cAlligator.sinalConfirmacao(sinalAConfirmar)); break;
      case ICHIMOKU_KINKO_HYO :
         return(cIchimoku.sinalConfirmacao(sinalAConfirmar)); break;
      case ADAPTIVE_CHANNEL_ADX :
         return(cAdaptiveChannelADX.sinalConfirmacao(sinalAConfirmar)); break;
      case PRICE_CHANNEL :
         return(cPriceChannel.sinalConfirmacao(sinalAConfirmar)); break;
      case BUY_SELL_PRESSURE :
         return(cBuySellPressure.sinalConfirmacao(sinalAConfirmar)); break;
      case INSIDE_BAR :
         return(cInsideBar.sinalConfirmacao(sinalAConfirmar)); break;
      case FREELANCE_JOB :
         return(cFreelanceJob.sinalConfirmacao(sinalAConfirmar)); break;
      case TABAJARA : return(cTabajara.sinalConfirmacao(sinalAConfirmar)); break;
      case CANAL_DESVIO_PADRAO : return(cCanalDesvioPadrao.sinalConfirmacao(sinalAConfirmar)); break;
      case CANAL_DONCHIAN : return(cCanalDonchian.sinalConfirmacao(sinalAConfirmar)); break;
      case SILVER_CHANNEL : return(cSilverChannel.sinalConfirmacao(sinalAConfirmar)); break;
      case PRICE_CHANNEL_GALLAHER : return(cPriceChannelGallaher.sinalConfirmacao(sinalAConfirmar)); break;
   }
   
   return(0);
}

//+------------------------------------------------------------------+
//|  Chama o método notificarUsuario() da estratégia selecionada     |
//|  para poder realizar notificar o usuário de algum evento em      |
//|  particular ou de uma intervenção que precisa ser feita durante a|
//|  negociação. O método recebe um sinal de chamada, que identifica |
//|  qual evento realizou a chamada.                                 |
//+------------------------------------------------------------------+
void notificarUsuario(int sinalChamada) {

   switch(estrategiaNegociacao) {
      case TENDENCIA_NRTR : 
         cTendenciaNRTR.notificarUsuario(sinalChamada); break;
      case FOREX_XAUEUR : 
         cForexXAUEUR.notificarUsuario(sinalChamada); break;
      case FOREX_XAUUSD : 
         cForexXAUUSD.notificarUsuario(sinalChamada); break;
      case FOREX_XAUAUD : 
         cForexXAUAUD.notificarUsuario(sinalChamada); break;
   }

}

//+------------------------------------------------------------------+
//| Retorna o valor do stop loss de acordo com os critérios definidos|
//| pela estratégia selecionada.                                     |
//+------------------------------------------------------------------+
double obterStopLoss(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   switch(estrategiaNegociacao) {
      case BMFBOVESPA_FOREX : 
         return(cBMFBovespaForex.obterStopLoss(tipoOrdem, preco)); break;
      case BUY_SELL_PRESSURE : 
         return(cBuySellPressure.obterStopLoss(tipoOrdem, preco)); break;
      case FREELANCE_JOB :
         return(cFreelanceJob.obterStopLoss(tipoOrdem, preco)); break;
      case TABAJARA : return(cTabajara.obterStopLoss(tipoOrdem, preco)); break;
   }

   return(0);
}

//+------------------------------------------------------------------+
//| Retorna o valor do take profit de acordo com os critérios        |
//| definidos pela estratégia selecionada.                           |
//+------------------------------------------------------------------+
double obterTakeProfit(ENUM_ORDER_TYPE tipoOrdem, double preco) {

   switch(estrategiaNegociacao) {
      case BMFBOVESPA_FOREX : 
         return(cBMFBovespaForex.obterTakeProfit(tipoOrdem, preco)); break;
      case BUY_SELL_PRESSURE :
         return(cBuySellPressure.obterTakeProfit(tipoOrdem, preco)); break;
      case FREELANCE_JOB :
         return(cFreelanceJob.obterTakeProfit(tipoOrdem, preco)); break;
      case TABAJARA : return(cTabajara.obterTakeProfit(tipoOrdem, preco)); break;
   }

   return(0);
}

//+------------------------------------------------------------------+
//|  Função responsável por confirmar o sinal de negociação indicado |
//|  na abertura da nova barra e abrir uma nova posição de compra/   |
//|  venda de acordo com a tendência do mercado.                     |
//+------------------------------------------------------------------+
void confirmarSinal() {

   //--- Obtém o sinal de confirmação recebido
   int sinalConfirmado = sinalConfirmacao();
   
   if (sinalAConfirmar > 0 && sinalConfirmado == 1) {
      
      //--- Verifica se existe uma posição de compra já aberta
      if (cOrder.existePosicoesAbertas(POSITION_TYPE_BUY)) {
         //--- Substituir com algum código útil
      } else {
                  
         //--- Confere se a posição contrária foi realmente fechada
         if (!cOrder.existePosicoesAbertas(POSITION_TYPE_SELL)) {
            //--- Abre a nova posição de compra
            realizarNegociacao(ORDER_TYPE_BUY);
         }
         
      }
      
   } else if (sinalAConfirmar < 0 && sinalConfirmado == -1) {
         
      //--- Verifica se existe uma posição de venda já aberta
      if (cOrder.existePosicoesAbertas(POSITION_TYPE_SELL)) {
         //--- Substituir com algum código útil
      } else {
         
         //--- Confere se a posição contrária foi realmente fechada
         if (!cOrder.existePosicoesAbertas(POSITION_TYPE_BUY)) {
         
            //--- Abre a nova posição de venda
            realizarNegociacao(ORDER_TYPE_SELL);
         }
      }
      
   } else {
      //--- Delega para a estratégia a realização da abertura de novas posições
      //--- e o fechamento das existentes.
      switch(estrategiaNegociacao) {
         case INSIDE_BAR :
            cInsideBar.realizarNegociacao(); break;
      }
   }
   
}
   
//+------------------------------------------------------------------+
//|  Função responsável por realizar a negociação propriamente dita, |
//|  obtendo as informações do último preço recebido para calcular o |
//|  spread, stop loss e take profit da ordem a ser enviada.         |
//+------------------------------------------------------------------+   
void realizarNegociacao(ENUM_ORDER_TYPE tipoOrdem) {

   //--- Obtém o valor do spread
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   //--- Obtém o tamanho do tick
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   //--- Obtém as informações do último preço da cotação
   MqlTick ultimoPreco;
   if (!SymbolInfoTick(_Symbol, ultimoPreco)) {
      Print("Erro ao obter a última cotação! - Erro ", GetLastError());
      return;
   }
   
   if (tipoOrdem == ORDER_TYPE_BUY) {
   
      // Verifica se existe margem disponível para abertura na nova posição de compra
      if (!cOrder.possuiMargemParaAbrirNovaPosicao(cMoney.obterTamanhoLote(), _Symbol, POSITION_TYPE_BUY)) {
         //--- Emite um alerta informando a falta de margem disponível
         cUtil.enviarMensagem(TERMINAL, "Sem margem disponível para abertura de novas posições!");
         return;
      }
      
      //--- Ajusta o preço nos casos do tick vier com um valor inválido
      double preco = ultimoPreco.ask;
      
      if (mercadoAOperar == SYMBOL_CALC_MODE_EXCH_STOCKS || mercadoAOperar == SYMBOL_CALC_MODE_EXCH_FUTURES) {
         // Diminui o resto da divisão do preço com o tick size para igualar ao
         // último múltiplo do valor de tick size
         if (fmod(preco, tickSize) != 0) {
            preco = preco - fmod(preco, tickSize);
         }
      }
      
      //--- Envia a ordem de compra
      cOrder.enviaOrdem(ORDER_TYPE_BUY, 
         TRADE_ACTION_DEAL, 
         preco, 
         cMoney.obterTamanhoLote(), 
         obterStopLoss(tipoOrdem, preco), 
         obterTakeProfit(tipoOrdem, preco));
   
   } else {
   
      // Verifica se existe margem disponível para abertura na nova posição de venda
      if (!cOrder.possuiMargemParaAbrirNovaPosicao(cMoney.obterTamanhoLote(), _Symbol, POSITION_TYPE_SELL)) {
         //--- Emite um alerta informando a falta de margem disponível
         cUtil.enviarMensagem(TERMINAL, "Sem margem disponível para abertura de novas posições!");
         return;
      }
      
      //--- Ajusta o preço nos casos do tick vier com um valor inválido
      double preco = ultimoPreco.bid;
      
      if (mercadoAOperar == SYMBOL_CALC_MODE_EXCH_STOCKS || mercadoAOperar == SYMBOL_CALC_MODE_EXCH_FUTURES) {
         // Diminui o resto da divisão do preço com o tick size para igualar ao
         // último múltiplo do valor de tick size
         if (fmod(preco, tickSize) != 0) {
            preco = preco - fmod(preco, tickSize);
         }
      }

      //--- Envia a ordem de venda
      cOrder.enviaOrdem(ORDER_TYPE_SELL, 
         TRADE_ACTION_DEAL, 
         preco, 
         cMoney.obterTamanhoLote(), 
         obterStopLoss(tipoOrdem, preco), 
         obterTakeProfit(tipoOrdem, preco));
    
   } 
}

//+------------------------------------------------------------------+ 
//|  Retorna true quando aparece uma nova barra no gráfico           |
//|  Função obtida no seguinte tópico de ajuda:                      |
//|  https://www.mql5.com/pt/docs/event_handlers/ontick              |
//+------------------------------------------------------------------+ 
bool temNovaBarra() {

   static datetime barTime = 0; // Armazenamos o tempo de abertura da barra atual
   datetime currentBarTime = iTime(_Symbol, _Period, 0); // Obtemos o tempo de abertura da barra zero
   
   //-- Se o tempo de abertura mudar, é porque apareceu uma nova barra
   if (barTime != currentBarTime) {
      barTime = currentBarTime;
      if (MQL5InfoInteger(MQL5_DEBUGGING)) {
         //--- Exibimos uma mensagem sobre o tempo de abertura da nova barra
         PrintFormat("%s: nova barra em %s %s aberta em %s", __FUNCTION__, _Symbol,
            StringSubstr(EnumToString(_Period), 7), TimeToString(TimeCurrent(), TIME_SECONDS));
      }
      
      return(true); // temos uma nova barra
   }

   return(false); // não há nenhuma barra nova
}

//+------------------------------------------------------------------+ 
//|  Retorna true caso esteja dentro do perído permitido pelo        |
//|  mercado que o usuário está operando (BM&FBovespa ou Forex).     |
//|                                                                  |
//|  Todas as ordens pendentes e posições abertas são encerradas     |
//|  quando estão fora dos horários dos pregões.                     |
//+------------------------------------------------------------------+  
bool mercadoAberto(MqlDateTime &hora) {

   switch(mercadoAOperar) {
      case SYMBOL_CALC_MODE_EXCH_STOCKS:
      case SYMBOL_CALC_MODE_EXCH_FUTURES:
         //--- Verifica se a hora está entre 10h e 17h
         if (hora.hour >= 10 && hora.hour < 17) {
            return(true);
         }      
         break;
      case SYMBOL_CALC_MODE_FOREX:
      case SYMBOL_CALC_MODE_CFD:
         if ( (hora.day_of_week == 1 && hora.hour == 0) || (hora.day_of_week == 5 && hora.hour == 23) ) {
            //--- Sai do switch para poder fechar as ordens e posições abertas
            break;
         } else {
            return(true);
         }
         
         break;
   }
   
   //--- Caso a hora não se encaixa em nenhuma das condições acima, todas as ordens
   //--- pendentes e posições abertas são fechadas
         
   //-- Fecha todas as posições abertas
   if (PositionsTotal() > 0) {
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         cOrder.fecharPosicao(PositionGetTicket(i));
      }
   }
   
   return(false);
}
//+------------------------------------------------------------------+