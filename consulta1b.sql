WITH base AS (
    SELECT
        r.periodo,
        SUM(CASE WHEN r.cuenta = 'INGRESOS FINANCIEROS'          THEN r.monto_miles_soles END) AS ingresos_acum,
        SUM(CASE WHEN r.cuenta = 'GASTOS FINANCIEROS'            THEN r.monto_miles_soles END) AS gastos_acum,
        SUM(CASE WHEN r.cuenta = 'MARGEN FINANCIERO BRUTO'       THEN r.monto_miles_soles END) AS margen_acum,
        SUM(CASE WHEN r.cuenta = 'RESULTADO NETO DEL EJERCICIO'  THEN r.monto_miles_soles END) AS neto_acum
    FROM estado_resultados r
    JOIN entidades e ON e.entidad_id = r.entidad_id
    WHERE e.nombre = 'Mibanco'
      AND r.moneda = 'TOTAL'
      AND r.cuenta IN ('INGRESOS FINANCIEROS', 'GASTOS FINANCIEROS',
                       'MARGEN FINANCIERO BRUTO', 'RESULTADO NETO DEL EJERCICIO')
    GROUP BY r.periodo
),
con_anterior AS (
    SELECT
        periodo, ingresos_acum, gastos_acum, margen_acum, neto_acum,
        LAG(ingresos_acum) OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS ingresos_prev,
        LAG(gastos_acum)   OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS gastos_prev,
        LAG(margen_acum)   OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS margen_prev,
        LAG(neto_acum)     OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS neto_prev
    FROM base
)
SELECT
    periodo,
    ROUND(ingresos_acum - COALESCE(ingresos_prev, 0), 1) AS ingresos_mes,
    ROUND(gastos_acum   - COALESCE(gastos_prev,   0), 1) AS gastos_mes,
    ROUND(margen_acum   - COALESCE(margen_prev,   0), 1) AS margen_bruto_mes,
    ROUND(neto_acum     - COALESCE(neto_prev,     0), 1) AS neto_mes,
    ROUND( (margen_acum - COALESCE(margen_prev, 0)) * 100.0
         / (ingresos_acum - COALESCE(ingresos_prev, 0)), 1) AS margen_pct
FROM con_anterior
WHERE periodo > '2025-09-30'
ORDER BY periodo;
