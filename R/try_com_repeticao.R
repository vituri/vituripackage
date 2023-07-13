#' Tenta executar um função repetidas vezes, com tempo de espera entre elas
#' @param expr Expressão a ser executada
#' @param tentativas Quantidade de tentativas
#' @param Texto_funcao O texto que será exibido caso falhe
#' @param tempo_espera_entre_tentativas O tempo de espera entre as tentativas, caso dê erro
#' @param valor_se_erro Valor final caso dê erro. É possível usar stop("texto") para ainda dar erro após todas as tentativas.
#' @export
try_com_repeticao = function(
    expr, tentativas = 5, texto_funcao = "função x", tempo_espera_entre_tentativas = 0
    ,valor_se_erro = NULL
) {
  contador = 1

  while (TRUE) {

    # cli::cli_progress_step('Iteração {contador}...')
    valor = try(expr = eval.parent(substitute(expr)), silent = TRUE)

    # se não é erro, sai
    if (argusinterno::is_try_error(valor) == FALSE) {

      if (contador > 1) {
        cli::cli_progress_step('Função {texto_funcao} executado na tentativa {contador}')
      }

      break
    }

    # se deu mais que tentativas, sai
    if (contador >= tentativas) {
      cli::cli_progress_step('Função {texto_funcao} tentou ser executada {contador} vezes, mas sem sucesso...')
      valor = valor_se_erro
      break
    }

    contador = contador + 1
    Sys.sleep(tempo_espera_entre_tentativas)

  }

  return(valor)
}
