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
  sistema_operacional = Sys.info()['sysname']

  if (sistema_operacional == "Linux") {
    system2(command = "xdg-open", args = arquivo)
  } else {
    shell.exec(arquivo)
  }
}

#' Abre uma tabela no Excel
#'
#' @description Abre arquivos no Linux e no Windows
#'
#' @param x Dataframe
#' @param nome_opcional Nome opctional do arquivo. Se nulo, vai como tabela.xlsx
#'
#' @export
abre_tabela_excel = function(x, nome_opcional = NULL) {

  if (is.null(nome_opcional)) {
    nome_opcional = 'tabela.xlsx'
  } else {
    nome_opcional = paste0(nome_opcional, '.xlsx')
  }

  write.xlsx(x = x, file = nome_opcional)

  abre_arquivo(nome_opcional)

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
           data_final = today(tz = 'Brazil/East') + days(8),
           dia_em_que_comeca_a_semana = 0,
           semana = TRUE,
           mes = TRUE,
           ano = TRUE,
           dia_semana = FALSE,
           dia_character = FALSE) {

    data_inicial %<>% as_date(tz = 'Brazil/East')

    data_final %<>% as_date(tz = 'Brazil/East')

    temp = seq_date(from = data_inicial - days(6), to = data_inicial)

    id = which(strftime(temp, '%w') == dia_em_que_comeca_a_semana)

    dias_diferenca = (data_final - data_inicial) %>% as.numeric()

    qtd_semanas = (dias_diferenca %/% 7) + 1

    calendario = tibble(
      Dia = seq_date(from = temp[id], to = temp[id] + days(7*qtd_semanas - 1))
    )

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

    # tá dando pau aqui com caractere
    if (mes == TRUE){
      calendario$Mês = calendario$Dia %>% format("%Y-%m-01")

      # calendario[['Mês']] = calendario$Mes
      # calendario[['Mes']] = NULL
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

dia_recente_da_semana = function(data_a_considerar = lubridate::today(tz = 'Brazil/East'), dia_da_semana = 0) {
  dias_pra_tras = data_a_considerar - lubridate::days(0:6)
  dia = dias_pra_tras[which(format(dias_pra_tras, '%w') == dia_da_semana)]

  return(dia)
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

#' Gera sequência de dias
#' @param from De onde
#' @param to Até onde
#' @param by De quantos em quantos dias
#'
#' @return Um vetor com a sequência
#'
#' @export
seq_date = function(from = today(tzone = 'Brazil/East'), to = today(tzone = 'Brazil/East'), by = 1) {
  if (is.character(from)) from %<>% as_date()
  if (is.character(to)) to %<>% as_date()

  if (from > to) {
    by = -by
  }

  seq.Date(from = from, to = to, by = by)
}


#' Retorna amostra de vetor
#' @description Versão mais sensata da função `sample`.``
#' @param x O vetor de onde tirar a amostra
#' @param size O tamanho da amostra
#' @param replace Os valores retornam para a caixa e podem ser selecionados novamente?
#'
#' @return Um vetor com a sequência
#'
#' @export
sample_safe = function(x = 1, size = length(x), replace = FALSE) {

  if (length(x) <= 1) {
    return (rep(x, times = size))
  }

  if (length(x) < size) {
    replace = TRUE
  }

  sample(x = x, size = size, replace = replace)
}

#' Translate anonymous
#'
#' Given an injective table Original vs Anonymous, translates a vector to an anonymous vector.
#'
#' @param x To be translated.
#' @param translate_table Reference table, with columns Original and Anonymous
#' @return Translated x
#' @export
translate_anonymous <-
  function(x, translate_table){
    y = tibble(Original = x %>% as.character(), order = x) %>%
      left_join(translate_table, by = "Original") %>% mutate(es = case_when(!is.na(Anonymous) ~
                                                                              Anonymous, TRUE ~ Original))
    if (is.factor(x)) {
      y = factor(y$Anonymous, y %>% arrange(order) %>% pull(Anonymous) %>%
                   unique())
    }
    else {
      y = y$Anonymous
    }
    return(y)
  }

#' Anonymize
#'
#' Given a list of tables, anonimyzes the specified columns
#'
#' @param tables Dataframe list
#' @param columns Columns to anonymize
#' @return Original list, but with anonymized columns. If there were columns of same name in different tables, elements in common will have the same anonymization
#' @export
#'
#' @examples
#' anonymize(list(iris), "Species")
anonymize <- function(tables, columns, seed = NULL){

  if(class(tables) != 'list'){stop('tables must be a list')}
  if(! 'tbl' %in% c(lapply(tables, class) %>% unlist() %>% unique())){'tables must be a dataframe list'}
  if(class(columns) != 'character'){stop('columns must be character')}

  columns_to_hide <- tables %>% lapply(names) %>% unlist() %>% intersect(columns)

  if(length(columns_to_hide) > 0){
    whole_table <- bind_rows(tables)

    if(!is.null(seed)){
      set.seed(seed)
    }
    reference_table <-
      tibble(Column = columns_to_hide) %>%
      rowwise() %>%
      mutate(Valid_list = list(whole_table %>% .[[Column]] %>% unique() %>% .[!is.na(.)])) %>%
      filter(length(Valid_list) > 0) %>%
      mutate(Tabela_trad = list(
        tibble(
          Original = Valid_list,
          Anonymous = stringi::stri_rand_strings(n = length(Valid_list), length = nchar(Valid_list[[1]] %>% as.character()), pattern = '[A-Z0-9]')
        ))) %>%
      ungroup()

    for(t in seq_along(tables)){

      for(col in names(tables[[t]]) %>% intersect(reference_table$Column)){
        tables[[t]][col] <-
          tables[[t]][[col]] %>%
          translate_anonymous(translate_table = reference_table %>% filter(Column == col) %>% pull(Tabela_trad) %>% .[[1]] )
      }

    }
  }

  tables

}
