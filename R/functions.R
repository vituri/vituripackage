


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

#' Envia emails usando o Outlook
#'
#' @description Monte emails usando o R e envie com o Outlook, com anexos, múltiplos contatos, etc. O
#'     email pronto será exibido e bastará apertar enviar. Só funciona usando R 3.6 (e não o 4).
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
#' @param usar_utf8 Se FALSE (o padrão é TRUE), converte o assunto e o texto pro formato native.
#' @details O pacote RDCOMclient é meio chato de instalar. Se ao usar essa função
#' ele der erro de instalação, provavelmente terá que apagar um arquivo chamado
#' LOCK-não-sei-o-que (conforme escrito no erro que der) e tentar usar a função de novo. É preciso
#' instalar o Rtools35.
#'
#' @export

email_outlook = function(para = "", cc = "", bcc = "", assunto = "",
                         texto_email = "", assinatura = "", anexos = "",
                         exibir_email = TRUE, enviar_email = FALSE, usar_utf8 = TRUE, anexo_utf8 = TRUE){
  # carrega o pacote
  if (require(RDCOMClient) == FALSE) {
    if (version$major %in% '3') {
      devtools::install_github("dkyleward/RDCOMClient")
    } else {
      install.packages("RDCOMClient", repos = "http://www.omegahat.net/R")
    }
  }

  require(RDCOMClient)

  # Open Outlook
  Outlook <- COMCreate("Outlook.Application")

  # Create a new message
  Email = Outlook$CreateItem(0)

  # Set the recipient, subject, and body
  Email[["to"]] = para %>% paste(collapse = "; ")
  Email[["cc"]] = cc %>% paste(collapse = "; ")
  Email[["bcc"]] = bcc %>% paste(collapse = "; ")
  if (usar_utf8 == TRUE) {
    Email[["subject"]] = assunto %>% as.character()
  } else {
    Email[["subject"]] = assunto %>% as.character() %>% enc2native()
  }

  if (usar_utf8 == TRUE) {
    Email[["HTMLBody"]] = paste0(texto_email, "<br>", assinatura)
  } else {
    Email[["HTMLBody"]] = paste0(texto_email, "<br>", assinatura) %>% enc2native()
  }

  if (all(anexos != "")) {

    arquivos =
      anexos %>%
      normalizePath()

    if (anexo_utf8 == FALSE) {
      arquivos %<>% enc2native()
    }

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


#' Gera um calendário
#'
#' @description Gera uma tabela com dias, semanas, mês e ano, para usar
#' em algum left_join e assim agrupar seus dados por semana/mês/ano.
#'
#' @param data_inicial Data inicial do calendário.
#' @param data_final Data final do calendário.
#' @param dia_em_que_comeca_a_semana Iniciais do dia da semana em que
#' a semana começa no calendário. Valores possívels:
#' 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'.
#' @param semana Se TRUE, o calendário terá coluna 'Semana'.
#' @param mes Se TRUE, o calendário terá coluna 'Mês'.
#' @param ano Se TRUE, o calendário terá coluna 'Ano'.
#' @param dia_character Se TRUE, a coluna 'Dia' vem como character.
#'
#' @return Um dataframe.
#'
#' @export

gera_calendario =
  function(data_inicial = "2018-01-01",
           data_final = today(),
           dia_em_que_comeca_a_semana = "dom",
           semana = TRUE,
           mes = TRUE,
           ano = TRUE,
           dia_semana = FALSE,
           dia_character = FALSE) {

    data_inicial %<>% as_date()

    data_final %<>% as_date()

    temp = seq.Date(from = data_inicial - days(6),
                    to = data_inicial, by = 1)

    id = which(weekdays(x = temp, abbreviate = TRUE) == dia_em_que_comeca_a_semana, useNames = FALSE)

    dias_diferenca = (data_final - data_inicial) %>% as.numeric()

    qtd_semanas = (dias_diferenca %/% 7) + 1

    calendario = data.frame(Dia = seq.Date(from = temp[id],
                                           to = temp[id] + days(7*qtd_semanas - 1), by = 1))

    n = length(calendario$Dia)

    calendario$Semana = calendario$Dia[1]

    for (i in seq(1, n, by = 7)) {
      calendario$Semana[i:(i+6)] = calendario$Dia[i]
    }

    if (dia_semana == TRUE) {
      calendario$Dia_Semana = weekdays(calendario$Dia, abbreviate = TRUE)
    }

    if (semana == FALSE) {
      calendario %<>% select(-Semana)
    }

    if (mes == TRUE){
      calendario$Mês = calendario$Dia %>% format("%Y-%m-01")
    }

    if (ano == TRUE) {
      calendario$Ano = calendario$Dia %>% year() %>% as.character()
    }

    if (dia_character == TRUE){
      calendario$Dia %<>% as.character()
    }

    return(calendario)
  }

#' Zipa arquivos.
#'
#' @description Cria uma pasta zipada com arquivos selecionados.
#' @param nome_pasta_zipada Nome da pasta zipada.
#' @param arquivos Arquivos para zipar.
#' @param nivel_de_compressao Inteiro de 1 a 9: quanto maior, mais comprimido
#' porém leva mais tempo.
#'
#' @return Um arquivo .zip no local especificado.
#'
#' @export

zipa_arquivos = function(nome_pasta_zipada, arquivos, nivel_de_compressao = 9) {
  if (require(zip) == FALSE) {
    devtools::install_github("r-lib/zip")
  } else {
    require(zip)
  }

  zipr(zipfile = nome_pasta_zipada, files = arquivos, compression_level = nivel_de_compressao)

}


#' Procura a data mais recente em que ocorreu um dia da semana.
#'
#' @param data_a_considerar Data a partir da qual procurar uma semana pra trás.
#' @param dia_da_semana Abreviado. Valores: seg, ter, qua, qui, sex, sáb, dom.
#'
#' @return Um objeto date com a data mais recente que cai no dia da semana selecionado.
#'
#' @export

dia_recente_da_semana = function(data_a_considerar = lubridate::today(), dia_da_semana = "seg") {
  dias_pra_tras = data_a_considerar - lubridate::days(0:6)
  dia = dias_pra_tras[which(weekdays(dias_pra_tras, abbreviate = TRUE) == dia_da_semana)]

  return(dia)
}


#' Auto atualizador do futuro
#'
#' @return Retorna nada, só pega a versão mais recente do github e carrega.
#'
#' @export
#'
carrega_pacote = function() {
  devtools::install_github("vituri/vituripackage", upgrade = 'never')
  library(vituripackage)
}

#' Checa se o try é um erro
#' @param x Objeto a ser testado
#'
#' @return TRUE se for erro, FALSE se não for.
#'
#' @export

eh_erro = function(x) {
  inherits(x, 'try-error')
}


#
# datatable(
#   data,
#   options = list(),
#   class = "display",
#   callback = JS("return table;"),
#   rownames,
#   colnames,
#   container,
#   caption = NULL,
#   filter = c("none", "bottom", "top"),
#   escape = TRUE,
#   style = "auto",
#   width = NULL,
#   height = NULL,
#   elementId = NULL,
#   fillContainer = getOption("DT.fillContainer", NULL),
#   autoHideNavigation = getOption("DT.autoHideNavigation", NULL),
#   selection = c("multiple", "single", "none"),
#   extensions = list(),
#   plugins = NULL,
#   editable = FALSE
# )
#
# datatable_simple = function(
#   data,
#   options = list(),
#   class = "display",
#   rownames = FALSE,
#   colnames,
#   container,
#   caption = NULL,
#   filter = c("none", "bottom", "top"),
#   escape = TRUE,
#   style = "auto",
#   width = NULL,
#   height = NULL,
#   elementId = NULL,
#   selection = c("multiple", "single", "none"),
#   extensions = list(),
#   editable = FALSE,
#   exibe_length_input = TRUE,
#   exibe_filtering = TRUE,
#   exibe_paginacao = TRUE,
#   exibe_botao = FALSE
#
#
# ) {
#
# }

#' A negação do %in%
#' @param a Vetor
#' @param b Vetor
#'
#' @return Logical
#'
#' @export

`%notin%` = function(a, b) {
  !a %in% b
}

waitress_infinite = function() {
  waitress <- waiter::Waitress$new(theme = "overlay-opacity", infinite = TRUE, hide_on_render = TRUE)

  return(waitress)
}

#' Gera sequência com o último termo incluso
#' @param from De onde
#' @param to Até onde
#' @param by De quanto em quanto
#'
#' @return Um vetor com a sequência
#'
#' @export
seq_com_fim = function(from, to, by) {
  c(seq(from = from, to = to, by = by), to) %>% unique()
}
