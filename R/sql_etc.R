
#' Escreve (dá append) numa base MariaDB
#'
#' @param conexao A conexão com o database.
#' @param nome_tabela Nome da tabela no database onde os dados serão salvos.
#' @param dados_a_serem_salvos A tabela com os dados a serem salvos no DB.
#' @param comando Comando para o INSERT, as opções são IGNORE ou REPLACE.
#' @export
#'
escreve_numa_base_mariadb2 = function(conexao, nome_tabela, dados_a_serem_salvos, comando = 'IGNORE')
{
  require(DBI)
  require(RMariaDB)

  # cria o endereço do arquivo temporário
  f = tempfile()

  # seleciona só os campos que existem na tabela de destino
  dbFields = DBI::dbListFields(conexao, nome_tabela)
  tabela = dados_a_serem_salvos %>% select(any_of(dbFields))

  # fixa os separadores
  sep = '|!|'
  eol = '|#|'

  # cria o arquivo temporário
  write.table(x = tabela, file = f, row.names = FALSE, col.names = FALSE,
              na = "\\N", fileEncoding = 'UTF-8',
              sep = sep, append = FALSE, eol = eol, quote = FALSE)

  # normaliza o endereço do arquivo
  arquivo = f %>% normalizePath(winslash = "/")

  # monta a query
  colunas = colnames(tabela) %>% glue_collapse(sep = '`,`')

  query = glue("
LOAD DATA LOCAL INFILE '{arquivo}'
{comando} INTO TABLE `{nome_tabela}`
CHARACTER SET 'utf8'
COLUMNS TERMINATED BY '{sep}'
LINES TERMINATED BY '{eol}'
(`{colunas}`)
")

  # executa a query
  DBI::dbExecute(conn = conexao, statement = query)

  # apaga o arquivo temporário
  unlink(f)
}


#' Transforma um vetor de string em um texto formatado pro sql
#' @param x Vetor de strings
#' @param data_para_mexer Data a partir da qual fazer a resumida
#'
#' @return Um vetor de tamanho 1
#'
#' @export

formata_string_sql = function(x) {
  paste0("('", x %>% paste0(collapse = "','"), "')")
}



#' Insere uma tabela no db via uma query gigante
#' @param .data Dataframe para ser escrito no banco
#' @param con Conexão com o database
#' @param nome_tabela_db Nome da tabela no database
#' @param comando Comando que vai ser usado na inserção
#'
#' @return O tanto de linhas que foi alterado (conta o insert e o update)
#'
#' @export
#'
escreve_tabela_sql_geral = function(.data, con, nome_tabela_db, comando = 'REPLACE') {

  colunas_da_tabela = DBI::dbListFields(conn = con, name = nome_tabela_db)

  colunas_em_comum = dplyr::intersect(colunas_da_tabela, names(.data))

  colunas_excluidas = dplyr::setdiff(names(.data), colunas_da_tabela)

  if (length(colunas_excluidas) != 0) {
    warning(glue('Colunas {diferenca %>% paste(collapse = ', ')} foram descartadas...'))
  }

  temp =
    .data %>%
    select(any_of(colunas_em_comum)) %>%
    tidyr::unite(col = '.unite', sep = "','") %>%
    pull(.unite)

  if (length(temp) == 0) {
    warning('Nada para salvar')
    return(NULL)
  }

  values =
    glue("('{temp}')") %>%
    glue_collapse(sep = ',')

  nomes_colunas_formatado =
    colunas_em_comum %>%
    glue_collapse(sep = "`,`") %>%
    paste0("(`", ., "`)")

  query = glue("{comando} INTO `{nome_tabela_db}` {nomes_colunas_formatado} VALUES {values}")

  # query

  DBI::dbExecute(conn = con, statement = query)
}
