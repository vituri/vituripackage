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

  return(y)
}

#' Tira ponto final da string
#'
#' @param x Um vetor de caracteres
#' @return O vetor sem pontos.
#' @examples
#' tira_ponto_da_string("texto.com.pontos")
#' @export

tira_ponto_da_string = function(x) {
  y =
    x %>%
    gsub(pattern = ".", replacement = "", fixed = TRUE, x = .)

  return(y)
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

  return(y)
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

  return(y)
}

#' Substitui um vetor de caracteres por outro caracter
#'
#' @param x Um vetor de caracteres
#' @param de Os caracteres a serem substituídos. Pode ser um vetor.
#' @param para O caracter pelo qual serão trocados os valores do vetor 'de'.
#'
#' @examples
#' substitui_string(x = "a < b > c", de = c("<", ">"), para = "!")
#'
#' @export
#'
substitui_string = function(x, de, para = "") {
  y = x
  for (padrao in de) {
    y %<>% gsub(x = ., pattern = padrao, replacement = para, fixed = TRUE)
  }

  return(y)
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
#' @details O pacote RDCOMclient é meio chato de instalar. Se ao usar essa função
#' ele der erro de instalação, provavelmente terá que apagar um arquivo chamado
#' LOCK-não-sei-o-que (conforme escrito no erro que der) e tentar usar a função de novo. É preciso
#' instalar o Rtools35.
#'
#' @export

email_outlook = function(para = "", cc = "", bcc = "", assunto = "",
                         texto_email = "", assinatura = "", anexos = "",
                         exibir_email = TRUE, enviar_email = FALSE){
  # carrega o pacote
  if (require(RDCOMClient) == FALSE) {
    devtools::install_github("dkyleward/RDCOMClient")
  } else {
    require(RDCOMClient)
  }

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

  # require(DBI); require(RSQLite)

  con = DBI::dbConnect(RSQLite::SQLite(),
                       dbname = local_database)

  return(tbl(con, nome_tabela))
}

#' Escreve dados no SQLite.
#'
#' @description Cria ou adiciona dados a uma tabela do SQLite
#'
#' @param dados_a_serem_salvos A tabela a ser salva no SQLite.
#' @param local_database Uma string com o caminho do database.
#' @param nome_tabela Nome da tabela do SQLite para acessar.
#' @param append Se os dados serão adicionados ao fim da tabela do SQLite (default: TRUE)
#' @param overwrite Se os dados sobrescreverão o que já existe no SQLite (default: FALSE)
#'
#' @details Use append = TRUE e overwrite = FALSE (padrão) para adicionar dados
#' a uma tabela já existente. Para sobrescrevê-la por completo, use
#' append = FALSE e overwrite = TRUE.
#'
#' @export
#'

escreve_numa_base_sqlite = function(dados_a_serem_salvos, local_database,
                                    nome_tabela, append = TRUE,
                                    overwrite = FALSE) {
  # require(DBI); require(RSQLite)

  con = DBI::dbConnect(RSQLite::SQLite(),
                       dbname = local_database)

  DBI::dbWriteTable(conn = con, name = nome_tabela,
                    value = dados_a_serem_salvos,
                    append = append, overwrite = overwrite)

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
           dia_character = FALSE) {

    data_inicial %<>% as_date()

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
