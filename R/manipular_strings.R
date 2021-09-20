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

#' Checa se a string possui um certo padrão
#'
#' @param x String a ser testada.
#' @param pattern Padrão pra procurar na string
#' @param ignore.case Ignorar se é maiuscula ou minúscula (por padrão, TRUE).
#'
#' @return Vetor booleano. É só uma versão mais paipeável do grepl.
#'
#' @export

padrao_string = function(x, pattern, ignore.case = TRUE) {
  grepl(x = x, pattern = pattern, ignore.case = ignore.case)
}


#' Checa se duas strings são iguais (sem dar pau com NA)
#' @param x String a ser testada.
#' @param y String a ser testada, de preferência do mesmo tamanho que x.
#'
#' @return Vetor booleano do memo tamanho que  x
#'
#' @export

compara_string = function(x, y) {
  1:length(x) %>%
    sapply(function(i) {
      identical(x[i], y[i])
    })
}


#' Data uma data, transforma em uma string no formato brasileiro. Tem opção de formatar pra mês/ano também.
#' @param x Vetor de datas.
#' @param tipo Semana ou mês. Se semana, fica dia/mês/ano. Se mês, fica mês/ano.
#'
#' @return Vetorzão da hora de characters.
#'
#' @export

converte_data_para_string = function(x, tipo = 'Semana') {
  y = x

  if (tipo %in% 'Semana') {
    y = x %>% format('%d/%m/%y')
  }

  if (tipo %in% 'Mês') {
    y = x %>% format('%m/%y')
  }

  return(y)
}
