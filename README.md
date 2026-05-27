# Projeto de Análise de Layoffs com SQL

Este projeto realiza a limpeza, padronização e análise exploratória de uma base de layoffs utilizando SQL em MySQL. O fluxo cobre etapas clássicas de um projeto de análise de dados.

## Ciclo de análise de dados

### Criação do ambiente de trabalho

O schema e a tabela staging são criados para separar a camada bruta da camada de transformação.

```sql
CREATE SCHEMA layoff;
CREATE TABLE layoff_staging LIKE layoffs.layoff;
INSERT layoff_staging SELECT * FROM layoffs.layoff;
```

### Remoção de duplicatas

A remoção de duplicatas é feita com função de janela. Esse é um recurso importante em análise de dados porque evita contagens infladas e melhora a confiabilidade das agregações.

```sql
INSERT layoff_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, `date`, stage, country
       ) AS row_num
FROM layoff_staging;

DELETE FROM layoff_staging2
WHERE row_num > 1;
```

### Padronização e tipagem

A base apresenta campos textuais com espaços extras, grafias inconsistentes e datas armazenadas como texto. Essas falhas comprometem a análise e por isso precisam ser corrigidas.

Exemplos:

```sql
UPDATE layoff_staging2 SET company = TRIM(company);
UPDATE layoff_staging2 SET industry = 'Crypto Currency' WHERE industry LIKE 'Crypto%';
UPDATE layoff_staging2 SET country = 'United States' WHERE country LIKE 'United S%';
UPDATE layoff_staging2 SET `date` = STR_TO_DATE(NULLIF(`date`, 'NULL'), '%m/%d/%Y');
ALTER TABLE layoff_staging2 MODIFY COLUMN `date` DATE;
```

### Tratamento de valores nulos

Valores nulos e vazios impactam filtros, agrupamentos e métricas. O projeto trata esses casos de forma explícita para reduzir distorções.

Exemplos de tratamento:

- Conversão de `'NULL'` e strings vazias para `NULL` real.
- Substituição de `stage = 'Unknown'` por `NULL`.
- Exclusão de registros sem `total_laid_off` e sem `percentage_laid_off`.
- Atualização de `industry` com base em registros equivalentes da mesma empresa e local.

## Consultas analíticas desenvolvidas

### Período da análise

```sql
SELECT MIN(`date`) AS start, MAX(`date`) AS end
FROM layoff_staging2;
```

Permite entender o intervalo temporal coberto pelos dados.

### Máximos absolutos e relativos

```sql
SELECT MAX(total_laid_off) AS absolute,
       MAX(percentage_laid_off) AS relative
FROM layoff_staging2;
```

Ajuda a identificar eventos extremos de demissão.

### Layoffs por empresa

```sql
SELECT company, SUM(total_laid_off) AS total
FROM layoff_staging2
GROUP BY company
ORDER BY 2 DESC;
```

Essa análise mostra quais empresas concentraram mais desligamentos no período.

### Layoffs por setor

```sql
SELECT industry, SUM(total_laid_off) AS total
FROM layoff_staging2
GROUP BY industry
ORDER BY 2 DESC;
```

Útil para identificar segmentos mais impactados economicamente.

### Layoffs por país

```sql
SELECT country, SUM(total_laid_off) AS total
FROM layoff_staging2
GROUP BY country
ORDER BY 2 DESC;
```

Essa consulta revela a distribuição geográfica das demissões.

### Layoffs por ano

```sql
SELECT YEAR(`date`), SUM(total_laid_off) AS total
FROM layoff_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;
```

Permite comparar anos com maior intensidade de layoffs.

### Layoffs por mês

```sql
SELECT SUBSTRING(`date`, 6, 2) AS month,
       YEAR(`date`) AS year,
       SUM(total_laid_off) AS total
FROM layoff_staging2
WHERE SUBSTRING(`date`, 6, 2) IS NOT NULL
  AND YEAR(`date`) IS NOT NULL
GROUP BY month, year
ORDER BY year, month;
```

Essa consulta ajuda na análise de sazonalidade e comportamento temporal.

### Total acumulado

```sql
WITH rolling_total AS (
    SELECT SUBSTRING(`date`, 6, 2) AS month,
           YEAR(`date`) AS year,
           SUM(total_laid_off) AS total
    FROM layoff_staging2
    WHERE SUBSTRING(`date`, 6, 2) IS NOT NULL
      AND YEAR(`date`) IS NOT NULL
    GROUP BY month, year
)
SELECT month,
       total,
       SUM(total) OVER (ORDER BY month, year) AS rolling_total
FROM rolling_total;
```

### Ranking por empresa e ano

```sql
WITH company_year (company, years, total_laid_off) AS (
    SELECT company,
           YEAR(`date`) AS year,
           SUM(total_laid_off) AS total
    FROM layoff_staging2
    GROUP BY company, YEAR(`date`)
    HAVING total IS NOT NULL AND year IS NOT NULL
)
SELECT *,
       DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
ORDER BY ranking;
```
