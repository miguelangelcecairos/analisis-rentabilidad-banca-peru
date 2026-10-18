WITH acum AS (
    SELECT
        r.entidad_id,
        e.nombre,
        r.periodo,
        SUM(CASE WHEN r.cuenta = 'INGRESOS FINANCIEROS'    THEN r.monto_miles_soles END) AS ingresos_acum,
        SUM(CASE WHEN r.cuenta = 'MARGEN FINANCIERO BRUTO' THEN r.monto_miles_soles END) AS margen_acum,
        SUM(CASE WHEN r.cuenta = 'GASTOS ADMINISTRATIVOS'  THEN r.monto_miles_soles END) AS gadm_acum
    FROM estado_resultados r
    JOIN entidades e ON e.entidad_id = r.entidad_id
    WHERE r.moneda = 'TOTAL'
      AND r.cuenta IN ('INGRESOS FINANCIEROS', 'MARGEN FINANCIERO BRUTO', 'GASTOS ADMINISTRATIVOS')
      AND e.nombre NOT LIKE 'Total%'
      AND e.nombre NOT LIKE '%Sucursales%'
      AND e.nombre <> 'Banco Efectiva'
    GROUP BY r.entidad_id, e.nombre, r.periodo
),
flujo AS (
    SELECT
        nombre,
        periodo,
        ingresos_acum - COALESCE(LAG(ingresos_acum) OVER (PARTITION BY entidad_id, strftime('%Y', periodo) ORDER BY periodo), 0) AS ingresos_mes,
        margen_acum   - COALESCE(LAG(margen_acum)   OVER (PARTITION BY entidad_id, strftime('%Y', periodo) ORDER BY periodo), 0) AS margen_mes,
        gadm_acum     - COALESCE(LAG(gadm_acum)     OVER (PARTITION BY entidad_id, strftime('%Y', periodo) ORDER BY periodo), 0) AS gadm_mes
    FROM acum
),
comparacion AS (
    SELECT
        periodo,
        SUM(CASE WHEN nombre =  'Mibanco' THEN ingresos_mes END) AS mib_ing,
        SUM(CASE WHEN nombre =  'Mibanco' THEN margen_mes   END) AS mib_mar,
        SUM(CASE WHEN nombre =  'Mibanco' THEN gadm_mes     END) AS mib_gadm,
        SUM(CASE WHEN nombre <> 'Mibanco' THEN ingresos_mes END) AS res_ing,
        SUM(CASE WHEN nombre <> 'Mibanco' THEN margen_mes   END) AS res_mar,
        SUM(CASE WHEN nombre <> 'Mibanco' THEN gadm_mes     END) AS res_gadm
    FROM flujo
    WHERE periodo > '2025-09-30'
    GROUP BY periodo
)
SELECT
    periodo,
    ROUND(mib_mar  * 100.0 / mib_ing, 1)                          AS mibanco_margen_pct,
    ROUND(res_mar  * 100.0 / res_ing, 1)                          AS resto_margen_pct,
    ROUND(mib_mar  * 100.0 / mib_ing - res_mar * 100.0 / res_ing, 1) AS dif_margen_pp,
    ROUND(mib_gadm * 100.0 / mib_ing, 1)                          AS mibanco_gadm_pct,
    ROUND(res_gadm * 100.0 / res_ing, 1)                          AS resto_gadm_pct,
    ROUND(mib_gadm * 100.0 / mib_ing - res_gadm * 100.0 / res_ing, 1) AS dif_gadm_pp
FROM comparacion
ORDER BY periodo;
