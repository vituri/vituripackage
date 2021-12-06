

gera_calendario =
  function(data_inicial = "2018-01-01",
           data_final = today(tz = 'Brazil/East'),
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


