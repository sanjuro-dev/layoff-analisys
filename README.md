# Layoff Data Analisys 

Este projeto apresenta um processo de limpeza e padronização de dados de layoffs usando SQL. O foco do trabalho é transformar uma tabela bruta (`layoff`) em uma base mais confiável para análise, removendo duplicatas, tratando valores nulos e vazios, padronizando textos e ajustando tipos de dados.
O objetivo é preparar os dados para análises posteriores, garantindo maior consistência e qualidade. O script cria um ambiente de trabalho separado, copia os dados da tabela staging e aplica sucessivas etapas de limpeza.



### Criação da base de trabalho
O script cria o schema `layoff` e usa uma cópia da tabela `layoff_staging` para preservar a base original.

### Remoção de duplicatas
As duplicatas são identificadas com `ROW_NUMBER()`, particionando pelos campos:
- `company`
- `location`
- `industry`
- `date`
- `stage`
- `country`

Depois disso, os registros repetidos são removidos da tabela auxiliar.

### Padronização de dados
Foram aplicadas padronizações como:
- Remoção de espaços extras em `company` com `TRIM()`.
- Padronização de valores de `industry`, como variações de `Cripto%` para `Crypto Currency`.
- Padronização de `country`, como valores iniciados em `United S%` para `United States`.

### Conversão de datas
A coluna `date`, originalmente em texto, é convertida com `STR_TO_DATE(..., '%m/%d/%Y')` e depois alterada para o tipo `DATE`.

### Tratamento de nulos e vazios
O script converte para `NULL` real os valores que estavam como:
- `'NULL'`
- `''` (string vazia)
- `Unknown` em alguns casos, como na coluna `stage`

Esse tratamento foi aplicado em colunas como:
- `industry`
- `total_laid_off`
- `percentage_laid_off`
- `date`
- `stage`
- `funds_raised_millions`

### Preenchimento de valores ausentes
Quando `industry` estava nulo, o script buscou outro registro com a mesma `company` e `location` para preencher esse valor automaticamente.

### Remoção de linhas irrelevantes
Registros com `total_laid_off` e `percentage_laid_off` ambos nulos foram removidos, pois não agregavam valor para análise.

### Ajuste final
Ao final do processo, a coluna auxiliar `row_num` é removida da tabela final.
