-- CONSULTA 1: flujo MENSUAL de Mibanco (ingresos, gastos y margen financiero bruto)
-- Los datos de la SBS vienen ACUMULADOS en el año. Aquí los convertimos a flujo mensual.
-- Cifras en miles de soles.

WITH base AS (
    -- Paso 1: una fila por mes con las 3 cuentas en columnas (acumulado del año)
    SELECT
        r.periodo,
        SUM(CASE WHEN r.cuenta = 'INGRESOS FINANCIEROS'      THEN r.monto_miles_soles END) AS ingresos_acum,
        SUM(CASE WHEN r.cuenta = 'GASTOS FINANCIEROS'        THEN r.monto_miles_soles END) AS gastos_acum,
        SUM(CASE WHEN r.cuenta = 'MARGEN FINANCIERO BRUTO'   THEN r.monto_miles_soles END) AS margen_acum
    FROM estado_resultados r
    JOIN entidades e ON e.entidad_id = r.entidad_id
    WHERE e.nombre = 'Mibanco'
      AND r.moneda = 'TOTAL'
      AND r.cuenta IN ('INGRESOS FINANCIEROS', 'GASTOS FINANCIEROS', 'MARGEN FINANCIERO BRUTO')
    GROUP BY r.periodo
),
con_anterior AS (
    -- Paso 2: traer el acumulado del mes anterior, pero SOLO dentro del mismo año
    -- (PARTITION BY año). En enero no hay mes anterior en el año, por eso sale NULL.
    SELECT
        periodo,
        ingresos_acum,
        gastos_acum,
        margen_acum,
        LAG(ingresos_acum) OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS ingresos_prev,
        LAG(gastos_acum)   OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS gastos_prev,
        LAG(margen_acum)   OVER (PARTITION BY strftime('%Y', periodo) ORDER BY periodo) AS margen_prev
    FROM base
)
-- Paso 3: flujo del mes = acumulado - acumulado anterior (si es NULL, se resta 0)
SELECT
    periodo,
    ROUND(ingresos_acum - COALESCE(ingresos_prev, 0), 1) AS ingresos_mes,
    ROUND(gastos_acum   - COALESCE(gastos_prev,   0), 1) AS gastos_mes,
    ROUND(margen_acum   - COALESCE(margen_prev,   0), 1) AS margen_bruto_mes
FROM con_anterior
-- Septiembre 2025 no se puede calcular: no tenemos enero-agosto 2025 cargados.
WHERE periodo > '2025-09-30'
ORDER BY periodo;
