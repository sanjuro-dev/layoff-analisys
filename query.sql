

-- TRATAR DADOS NULOS OU VAZIOS
-- REMOVER


CREATE SCHEMA layoff;

CREATE TABLE layoff_staging LIKE layoffs.layoff;
INSERT layoff_staging SELECT * FROM layoffs.layoff;

-- REMOVER DUPLICATAS



with cte_duplicates as (
    SELECT *, row_number() over (
        partition by company, location, industry,
        `date`, stage, country
    ) as row_num
    from layoff_staging
)
select * from cte_duplicates where row_num > 1;

create table layoff_staging2
(
    company               text null,
    location              text null,
    industry              text null,
    total_laid_off        text null,
    percentage_laid_off   text null,
    date                  text null,
    stage                 text null,
    country               text null,
    funds_raised_millions text null,
    row_num               int null
);

insert layoff_staging2 (SELECT *, row_number() over (
        partition by company, location, industry,
        `date`, stage, country
    ) as row_num from layoff_staging
);

DELETE FROM layoff_staging2 WHERE row_num > 1;
select * from layoff_staging2 where row_num > 1;

-- PADRONIZAR DADOS

update layoff_staging2 set company = trim(company);
select distinct * from layoff_staging2;

select distinct industry from layoff_staging2;
update layoff_staging2 set industry = 'Crypto Currency' where industry like 'Cripto%';
select distinct industry from layoff_staging2;

select distinct country from layoff_staging2 order by 1;
update layoff_staging2 set country = 'United States' where country like 'United S%';

SELECT `date`
FROM layoff_staging2
WHERE STR_TO_DATE(NULLIF(`date`, 'NULL'), '%m/%d/%Y') IS NULL
  AND `date` IS NOT NULL
  AND `date` != '';
update layoff_staging2 set `date` = STR_TO_DATE(nullif(`date`, 'NULL'),'%m/%d/%Y');

ALTER TABLE layoff_staging2
    MODIFY COLUMN `date` DATE;

select date from layoff_staging2;

select * from layoff_staging2 where industry = 'NULL' or '';
update layoff_staging2 set industry = null where industry = 'NULL' or industry = '';

select * from layoff_staging2 where total_laid_off = 'NULL' or total_laid_off ='';
update layoff_staging2 set total_laid_off = null where total_laid_off = 'NULL' or total_laid_off = '';

select * from layoff_staging2 where percentage_laid_off = 'NULL' or percentage_laid_off ='';
update layoff_staging2 set percentage_laid_off = null where percentage_laid_off = 'NULL' or percentage_laid_off = '';

select * from layoff_staging2 where `date` = 'NULL' or `date` ='';
update layoff_staging2 set `date` = null where `date` = 'NULL' or `date` = '';

select * from layoff_staging2 where stage = 'NULL' or stage ='' or stage='Unknown';
update layoff_staging2 set stage = null where stage = 'NULL' or stage = '' or stage='Unknown';

select * from layoff_staging2 where funds_raised_millions = 'NULL' or '';
update layoff_staging2 set funds_raised_millions = null where funds_raised_millions = 'NULL' or funds_raised_millions = '';

select * from layoff_staging2 where industry IS NULL;

select * from
layoff_staging2 t1 join layoff_staging2 t2
on t1.company = t2.company and t1.location = t2.location
where t1.industry is null and t2.industry is not null;

UPDATE layoff_staging2 t1
JOIN layoff_staging2 t2
    ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


SELECT COUNT(*) FROM layoff_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

delete from layoff_staging2
where total_laid_off is null and percentage_laid_off is null;

alter table layoff_staging2 drop row_num;