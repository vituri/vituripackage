
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



#' Escreve (dá append) numa base MariaDB
#'
#' @param conexao A conexão com o database.
#' @param nome_tabela Nome da tabela no database onde os dados serão salvos.
#' @param dados_a_serem_salvos A tabela com os dados a serem salvos no DB.
#' @param overwrite Se TRUE (padrão é FALSE), sobrescreve a tabela.
#' @param append Se TRUE (padrão), adiciona os dados ao fim da tabela existente, sem apagar nada.
#' @param encoding O encoding do csv que vai ser salvo pra depois subir pro mariadb. Se nulo,
#' tenta detectar sozinho de acordo com o sistema operacional. Às vezes é preciso forçar utf8
#' nele pra escrever direito no Linux. Não entendi o motivo ainda.
#' @export

escreve_numa_base_mariadb = function(conexao, nome_tabela, dados_a_serem_salvos,
                                     overwrite = FALSE, append = TRUE, encoding = NULL) {
  require(DBI)
  require(RMariaDB)
  if (Sys.info()["sysname"] %in% "Linux") {
    eol = "\n"
    fileEncoding = "latin1"
  } else {
    eol = "\r\n"
    fileEncoding = "UTF-8"
  }

  f = tempfile()
  dbFields = DBI::dbListFields(conexao, nome_tabela)
  if (append == TRUE) {
    for (dbField in dbFields) {
      if (!(dbField %in% colnames(dados_a_serem_salvos))) {
        dados_a_serem_salvos[[dbField]] = NA
      }
    }
  }

  dados_a_serem_salvos = dados_a_serem_salvos %>% select(all_of(dbFields))

  fileEncoding = if (is.null(encoding)) fileEncoding else encoding

  write.csv(dados_a_serem_salvos, file = f, row.names = F,
            na = "NULL", fileEncoding = fileEncoding, eol = eol)
  dbWriteTable(conexao, nome_tabela, f, append = append, overwrite = overwrite,
               eol = eol)
  unlink(f)
}

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
  DBI::dbExecute(conn = con, statement = query)

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
