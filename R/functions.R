#' Tira espaço dos elementos de um vetor.
#'
#' @param x Um vetor de caracteres
#' @return O vetor sem espaços.
#' @examples
#' tira_espaco_do_nome("texto com espaco")
#' @export

tira_espaco_da_string = function(x) {
  y =
    x %>%
    gsub(pattern = " ", replacement = "", fixed = TRUE, x = .)
}

#' Tira ponto final da string
#'
#' @param x Um vetor de caracteres
#' @return O vetor sem pontos.
#' @examples
#' tira_ponto_da_string("texto.com.pontos")
#' @export

tira_ponto_da_string = function(x, x1) {
  y =
    x %>%
    gsub(pattern = ".", replacement = "", fixed = TRUE, x = .)
}

#' Troca ponto final por espaço na string
#'
#' @param x Um vetor de caracteres
#' @return O vetor com espaço no lugar do ponto.
#' @examples
#' troca_ponto_por_espaco("texto.com.pontos")
#' @export

troca_ponto_por_espaco = function(x, x1) {
  y =
    x %>%
    gsub(pattern = ".", replacement = " ", fixed = TRUE, x = .)
}

#' Troca espaço por ponto final na string
#'
#' @param x Um vetor de caracteres
#' @return O vetor com ponto no lugar do espaço.
#' @examples
#' troca_espaco_por_ponto("texto com espaco")
#' @export
#'
troca_espaco_por_ponto = function(x, x1) {
  y =
    x %>%
    gsub(pattern = " ", replacement = ".", fixed = TRUE, x = .)
}



getCurrentFileLocation <-  function()
{
  this_file <- commandArgs() %>%
    tibble::enframe(x = ., name = NULL) %>%
    tidyr::separate(col=value, into=c("key", "value"), sep="=", fill='right') %>%
    dplyr::filter(key == "--file") %>%
    dplyr::pull(value)
  if (length(this_file)==0)
  {
    this_file <- rstudioapi::getSourceEditorContext()$path
  }
  return(dirname(this_file))
}

#' Define o working directory como sendo a pasta onde se encontra salvo o script.
#'
#' @return Muda o wd.
#' @export

set_wd_aqui = function() {
  setwd(getCurrentFileLocation())
}

#' Instala o pacote RDCOMClient (que se comunica com o pacote Office)
#'

instala_rdcomclient = function() {
  devtools::install_github("omegahat/RDCOMClient")
}

#' Envia emails usando o Outlook
#'
#' @description Monte emails usando o R e envie com o Outlook, com anexos, múltiplos contatos, etc. O
#'     email pronto será exibido e bastará apertar enviar.
#'
#' @param para Um vetor com emails (o que se escreve no 'para').
#' @param cc Um vetor com emails em cópia 'cc'.
#' @param bcc Um vetor com emails para cópia oculta.
#' @param assunto O assunto do email.
#' @param texto_email O texto do email (em html).
#' @param assinatura A assinatura do email (em html).
#' @param anexos Um vetor com o endereço dos anexos (o caminho pode estar relativo ao seu working directory).
#' @param exibir_email Se TRUE (padrão), exibe o email montado no Outlook (e voce envia apos checar).
#' @param enviar_email Se TRUE (o padrão é FALSE), envia o email logo após montar.
#' @details Caso dê um erro do tipo 'não foi possível encontrar o pacote RDCOMClient', use o comando instala_rdcomclient()
#'   É recomendado abrir o Outlook antes de usar essa função, pois senão o email vai pra caixa de saída (e não é enviado).
#'
#' @export

email_outlook = function(para = "", cc = "", bcc = "", assunto = "",
                         texto_email = "", assinatura = "", anexos = "",
                         exibir_email = TRUE, enviar_email = FALSE){
  # carrega o pacote
  require(RDCOMClient)

  # Open Outlook
  Outlook <- COMCreate("Outlook.Application")

  # Create a new message
  Email = Outlook$CreateItem(0)

  # Set the recipient, subject, and body
  Email[["to"]] = para %>% paste(collapse = "; ")
  Email[["cc"]] = cc %>% paste(collapse = "; ")
  Email[["bcc"]] = bcc %>% paste(collapse = "; ")
  Email[["subject"]] = assunto %>% as.character() %>% enc2native()
  Email[["HTMLBody"]] = paste0(texto_email, "<br>", assinatura)

  if (all(anexos != "")) {

    arquivos =
      anexos %>%
      normalizePath() %>%
      enc2native()

    for (i in 1:length(arquivos)) {
      Email[["Attachments"]]$Add(arquivos[i])
    }
  }

  if (exibir_email == TRUE) {
    Email$Display()
  }

  if (enviar_email == TRUE) {
    Email$Send()
  }

}

#' Abre um arquivo usando o programa padrão do sistema operacional
#'
#' @description Abre arquivos no Linux e no Windows
#'
#' @param arquivo Uma string com o caminho do arquivo.
#' @details Se não funcionar, use o caminho completo (em vez do caminho relativo).
#'
#' @export

abre_arquivo = function(arquivo){
  if (sistema_operacional == "Linux") {
    system2(command = "xdg-open", args = arquivo)
  } else {
    shell.exec(arquivo)
  }
}

#' Cria conexão com uma base do SQLite.
#'
#' @description Cria uma tabela 'simbólica' do SQLite.
#'
#' @param local_database Uma string com o caminho do database.
#' @param nome_tabela Nome da tabela do SQLite para acessar.
#'
#' @return Uma conexão com o SQLite.
#'
#' @details Essa função retorna uma tabela
#'   na memória. Você poderá manipular ela como se estivesse de fato,
#'   usando os verbos do dplyr. Quando quiser realmente obter os dados
#'   após seus comandos, utilize 'collect()'.
#'
#' @export
#'
conecta_base_sqlite = function(local_database, nome_tabela) {
  require(DBI); require(RSQLite)

  con = DBI::dbConnect(RSQLite::SQLite(),
                       dbname = local_database)

  return(tbl(con, nome_tabela))
}


gera_calendario = function(data_inicial, data_final = today(), dia_em_que_comeca_a_semana = "dom") {
  dia_em_que_comeca_a_semana = "dom"

  temp = seq.Date(from = "2019-12-01" %>% ymd(),
                  to = "2019-12-07" %>% ymd, by = 1)

  id = which(weekdays(x = temp, abbreviate = TRUE) == dia_em_que_comeca_a_semana, useNames = FALSE)

  calendario = data.frame(Dia = seq.Date(from = temp[id],
                                         to = temp[id] + days(7*250 - 1), by = 1))

  n = length(calendario$Dia)

  calendario$Semana = calendario$Dia[1]

  for (i in seq(1, n, by = 7)) {
    calendario$Semana[i:(i+6)] = calendario$Dia[i]
  }

  # calendario$Mês = calendario$Dia %>% format("%Y-%m-01")
  #
  # calendario$Ano = calendario$Dia %>% year() %>% as.character()
  #
  # calendario$Dia %<>% as.character()
  #
  # calendario %>% write.csv2(file = "calendario.csv", row.names = FALSE)
  #
  # calendario = read.csv2(file = "calendario.csv")
}
