
#' Lê a tratativa já com os nomes uniformes
#'
#' @param arquivo Local do arquivo: uma string com o endereço parcial ou completo.
#' @param use_openxlsx Decide se usa o openxlsx ou o readxl. O segundo dá pau com bad_alocc mas
#' às vezes mas é mais rápido. O openxlsx às vezes fica lendo pra sempre uma desgraça de excel e
#' só dá pra sair do R fechando pelo gerenciador de tarefas.
#'
#' @return data.frame chique.
#'
#' @export

le_tratativa_base_antiga = function(arquivo, use_openxlsx = FALSE, data_inicio, data_final) {

  glue('Lendo {basename(arquivo)}... {i} de {length(arquivos)} \n') %>% cat()

  if (use_openxlsx == TRUE) {
    temp = openxlsx::read.xlsx(xlsxFile = arquivo, startRow = 4, sheet = "B.TA",
                               skipEmptyRows = TRUE, skipEmptyCols = FALSE)
  } else {
    temp = readxl::read_excel(path = arquivo, skip = 3, sheet = "B.TA", guess_max = 200000)
  }

  n_col = min(38, ncol(temp))

  temp = temp[, 1:n_col]

  names(temp) = vituripackage::nomes_colunas_tratativas[1:n_col]

  temp$DataHora = lubridate::ymd_hms(temp$DataHora)

  temp %<>%
    select(Frota, Empresa, Eventos, `Tipo de distração`, `Tipo de alarme registrado`,
           Observações, DataHora, `Método de processamento`, `Descrição do processamento`,
           Velocidade, Endereço, Longitude, Latitude) %>%
    filter(DataHora >= data_inicio & DataHora < (data_final + days(1)))

  return(temp)
}

#' Pega a lista de tratativas e achata numa tabela só
#'
#' @param lista_de_tratativas Lista em que cada elemento é uma tabela.
#'
#' @return data.frame chique.
#'
#' @export

junta_tratativas_numa_tabela_so = function(lista_de_tratativas) {
  x =
    lista_de_tratativas %>%
    purrr::compact() %>%
    purrr::keep(.p = function(x) nrow(x) > 0) %>%
    lapply(function(tabela){
      x =
        tabela %>%
        mutate(across(!starts_with("DataHora"), ~ as.character(.)))

      x
    }) %>%
    bind_rows() %>%
    distinct()

  return(x)
}

#' Escreve direito os eventos de uma tratativa
#'
#' @param tabela Tabela com os eventos esculachados.
#'
#' @return data.frame chiquíssimo.
#'
#' @export

arruma_eventos_da_tratativa = function(tabela) {
  x = tabela

  x %<>%
    mutate(Eventos = case_when(
      Eventos %>% padrao_string('falso') ~ 'Falso Alarme',

      `Descrição do processamento` %>% padrao_string('falso') ~ 'Falso Alarme',

      Eventos %in% 'Sonolência' ~ case_when(
        `Tipo de alarme registrado` %>% padrao_string('n1') ~ 'Sonolência N1',
        `Tipo de alarme registrado` %>% padrao_string('n2') ~ 'Sonolência N2',
        TRUE ~ Eventos
      ),

      Eventos %in% 'Distração' ~ case_when(
        `Tipo de alarme registrado` %>% padrao_string('n1') ~ 'Olhando para baixo N1',
        `Tipo de alarme registrado` %>% padrao_string('n2') ~ 'Olhando para baixo N2',

        `Tipo de alarme registrado` %in% 'Olhar para o lado' &
          `Tipo de distração` %in% 'Olhar para o lado' ~ 'Olhar para o lado',

        `Tipo de alarme registrado` %in% 'Celular' &
          `Tipo de distração` %in% 'Celular' ~ 'Celular',

        `Tipo de alarme registrado` %in% 'Fumando' &
          `Tipo de distração` %in% 'Fumando' ~ 'Fumando',
        TRUE ~ Eventos
      ),

      `Tipo de alarme registrado` %>% padrao_string('bocejo') ~ 'Bocejo',
      TRUE ~ Eventos
    )
    )

  x %<>% arrange(lubridate::date(DataHora), Empresa)
  x$DataHora %<>% as.character()
  x$Latitude %<>% as.numeric()
  x$Longitude %<>% as.numeric()
  x$Velocidade %<>% as.numeric() %>% round(digits = 0) %>% as.character()

  return(x)
}

#' Lê várias tratativas e arquivos de processamento da base nova
#'
#' @param arquivos_eventos Local dos arquivos com as planilhas de eventos.
#' @param arquivos_processamentos Local dos arquivos com as planilhas de processamentos.
#'
#' @return data.frame chique.
#'
#' @export

le_tratativa_base_nova =
  function(arquivos_eventos, arquivos_processamentos = NULL) {

    # browser()
    temp1 =
      arquivos_eventos %>%
      lapply(function(arquivo) {
        temp = readxl::read_excel(path = arquivo, skip = 3)
      }) %>%
      bind_rows() %>%
      distinct()


    if (!is.null(arquivos_processamentos)) {
      temp2 =
        arquivos_processamentos %>%
        lapply(function(arquivo) {
          # browser()
          temp = readxl::read_excel(path = arquivo, skip = 2)
          temp$Velocidade %<>% as.numeric()
          names(temp)[5] = 'Organização controladora'
          temp %<>%
            rename(`Número de Placa` = `Número de placa de veículo`,
                   `Tipo de Alarme` = `Tipo de alarme`)

          return(temp)
        }) %>%
        bind_rows() %>%
        distinct()

      temp = left_join(temp1, temp2, by = c('Tipo de Alarme', 'Número de Placa', 'Hora de alarme'))
    } else {
      temp = temp1
    }

    return(temp)

  }


#' Vetor com os nomes das colunas das tratativas no modelo antigo.
#'
#' @return Um vetor da hora.
#'
#' @export

nomes_colunas_tratativas = c(
  "Número", "Frota", "Placa", "Empresa", "Motorista", "Telefone", "Eventos",
  "Tipo de distração", "Tipo de alarme registrado", "Observações", "DataHora",
  "Tempo de processamento", "Duração do processamento", "Estado de processamento",
  "Usuario manipulador", "Método de processamento", "Descrição do processamento", "Velocidade",
  "Endereço", "Data Hora Brasil", "Dia", "Horário", "Mês", "...24", "Id Imagem",
  "Id Motorista", "Foto Selecionada?", "Tratado Manualmente?", "Id Cadastro Plataforma Argus",
  "Alarme Ajustado para relatorio", "Id Video N2", "Duplicados", "Contagem Duplicados",
  "...34", "Periodo baixado", "...36", "Longitude", "Latitude")



#' Pega eventos da base de tratativas do mariadb e sobe pra base de Analytics correspondente
#' @param conexao_db_original Conexão com o db original de Analytics
#' @param conexao_db_tratativas Conexão com o db de tratativas
#' @param db_selecionado Nome do db selecionado (pra saber quais operações da tratativa
#' ele tem que pegar)
#' @param data_inicial Se NULL, usa '2018-01-01'
#' @param data_final Se NULL, usa o dia de ontem
#' @param usar_campo_empresa Se TRUE, busca o nome da empresa na coluna Nome_database da planilha Controle.
#' Se FALSE, busca pelo padrão do nome da operação.
#'
#' @return Retorna nada fi
#'
#' @export

consolida_base_tratativa_mariadb_nova = function(
  conexao_db_original, conexao_db_tratativas,
  db_selecionado, usar_campo_empresa = TRUE,
  data_inicial = NULL, data_final = NULL) {

  if (is.null(data_inicial)) {
    data_inicial = '2018-01-01'
  }

  if (is.null(data_final)) {
    data_final = today(tzone = 'Brazil/East') - days(1)
  }

  data_inicial %<>% as.character()

  data_final = data_final + days(1)
  data_final %<>% as.character()

  fx.controle =
    tbl(conexao_db_tratativas, 'Controle') %>%
    select(Nome_database, Operação)

  controle =
    fx.controle %>%
    collect()

  if (usar_campo_empresa == TRUE) {
    empresa_selecionada =
      controle %>%
      filter(Nome_database %>% padrao_string(db_selecionado)) %>%
      pull(Operação) %>%
      unique()
  } else {
    empresa_selecionada =
      controle %>%
      filter(Operação %>% padrao_string(db_selecionado)) %>%
      pull(Operação) %>%
      unique()
  }

  dados =
    tbl(conexao_db_tratativas, 'Eventos') %>%
    filter(Empresa %in% empresa_selecionada &
             `Horário registro` >= data_inicial &
             `Horário registro` < data_final) %>%
    collect()

  dados$`Horário de processamento` %<>% as.character()
  dados$`Horário registro` %<>% as.character()

  dados %<>%
    rename(DataHora = `Horário registro`,
           `Tipo de alarme registrado` = `Alarme registrado`)

  dados %<>%
    filter(!Eventos %in% 'Confirmação download')

  # con2 = argusinterno::conexao_mariadb(db_selecionado)

  glue('Baixando de {c(data_inicial, data_final) %>% unique() %>% paste(collapse = " a ")}') %>%
    cat()

  if (nrow(dados) > 0) {
    dados %>%
      escreve_numa_base_mariadb(conexao = conexao_db_original,
                                nome_tabela = 'Eventos', dados_a_serem_salvos = .)
    'Dados salvos!' %>% cat()
  } else {
    'Nenhum dado para salvar!' %>% cat()
  }

  return()
}



#' Gera o num_eventos_frota do período correspondente em diante
#' @param con Conexão com o database
#' @param data_para_mexer Data a partir da qual fazer a resumida
#'
#' @return Nadinha
#'
#' @export

gera_num_eventos_frota = function(con, data_para_mexer = '2018-01-01') {

  data_para_mexer %<>% as.character()

  texto = glue("REPLACE
  INTO num_eventos_frota (`Empresa`, `Frota`, `Dia`, `Bocejo`, `Sonolência N1`, `Sonolência N2`, `Celular`, `Fumando`, `Oclusão`, `Olhando para baixo N1`, `Olhando para baixo N2`)
  (SELECT `Empresa`, `Frota`, `Dia`, `Bocejo`, `Sonolência N1`, `Sonolência N2`, `Celular`, `Fumando`, `Oclusão`, `Olhando para baixo N1`, `Olhando para baixo N2`
    FROM (SELECT `Empresa`, `Frota`, `Dia`, SUM(`Bocejo`) AS `Bocejo`, SUM(`Sonolência N1`) AS `Sonolência N1`, SUM(`Sonolência N2`) AS `Sonolência N2`, SUM(`Celular`) AS `Celular`, SUM(`Fumando`) AS `Fumando`, SUM(`Oclusão`) AS `Oclusão`, SUM(`Olhando para baixo N1`) AS `Olhando para baixo N1`, SUM(`Olhando para baixo N2`) AS `Olhando para baixo N2`
          FROM (SELECT `Empresa`, `Frota`, `Bocejo`, `Sonolência N1`, `Sonolência N2`, `Celular`, `Fumando`, `Oclusão`, `Olhando para baixo N1`, `Olhando para baixo N2`, DATE(`DataHora`) AS `Dia`
                FROM `Eventos`
                WHERE (`DataHora` >= '{data_para_mexer}')) `q01`
          GROUP BY `Empresa`, `Frota`, `Dia`) `q02`)")

  DBI::dbExecute(con, texto)
}
