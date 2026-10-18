# Rentabilidad de Mibanco frente a la banca múltiple peruana (SQL)

Análisis en SQL de la rentabilidad mensual de **Mibanco** comparada con el resto de la banca múltiple del Perú, usando los estados financieros publicados por la SBS entre **septiembre 2025 y agosto 2026**.

**Autor:** Miguel Angel Cecairos Lopez · [LinkedIn](https://www.linkedin.com/in/miguelcecairos/)

## Pregunta que responde

¿Cuánto del ingreso financiero de Mibanco se convierte en margen financiero bruto cada mes, y cómo se compara con el resto de la banca? ¿Y cuánto gasta en operar por cada sol de ingreso?

## Datos

- **Fuente:** SBS, *Información Estadística de Banca Múltiple → Estados Financieros por Empresa Bancaria* (archivos `B-2201`, un archivo por mes, con balance general y estado de ganancias y pérdidas).
- **Periodo:** 12 meses, de septiembre 2025 a agosto 2026.
- **Unidad:** miles de soles. Se usa siempre la columna `TOTAL` (moneda nacional + extranjera).
- **Cobertura:** 24 entidades en la base. Para las comparaciones se excluyen las filas agregadas ("Total Banca Múltiple"), la fila de BCP con sucursales en el exterior (duplicaría a BCP) y Banco Efectiva (solo aparece 3 meses).

## Cómo se organiza

| Archivo | Qué hace |
|---|---|
| `load_sbs.py` | Convierte los archivos Excel de la SBS (formato ancho, un banco por bloque de columnas) a una base SQLite en formato largo: tablas `entidades`, `balance` y `estado_resultados`. |
| `consulta1_mibanco_flujo_mensual.sql` | Flujo mensual de Mibanco: ingresos, gastos y margen financiero bruto. |
| `consulta1b.sql` | Lo anterior más resultado neto mensual y margen financiero bruto en %. |
| `consulta2_comparacion.sql` | Mibanco frente al resto de la banca: margen bruto % y gasto administrativo sobre ingresos %, mes a mes. |

## Cómo reproducirlo

1. Descargar los 12 archivos mensuales de la SBS y ponerlos en una carpeta.
2. Generar la base: `python load_sbs.py carpeta_con_xls sbs.db`
3. Abrir `sbs.db` en [DB Browser for SQLite](https://sqlitebrowser.org/) y ejecutar las consultas en la pestaña *Ejecutar SQL*.

## Punto técnico clave: datos acumulados

El estado de ganancias y pérdidas de la SBS viene **acumulado en el año** (febrero incluye enero, y así hasta diciembre). Para obtener el resultado de cada mes hay que restar el acumulado del mes anterior, reiniciando en enero. Se resuelve con `LAG()` y `PARTITION BY` año (y por entidad en la consulta 2), usando `COALESCE` para enero. Septiembre 2025 se excluye porque no se cargaron enero a agosto de 2025 y su flujo no se puede calcular.

Técnicas SQL usadas: CTEs, `JOIN`, `GROUP BY`, agregación condicional (`SUM(CASE WHEN ...)`), funciones de ventana (`LAG ... OVER (PARTITION BY ... ORDER BY ...)`), `COALESCE`.

## Resultados (consulta 2)

Margen financiero bruto = margen financiero bruto / ingresos financieros. Gasto administrativo = gastos administrativos / ingresos financieros. "Resto" = suma de las demás bancas antes de dividir (no un promedio de porcentajes). `pp` = puntos porcentuales.

| Mes | Margen Mibanco | Margen resto | Dif. (pp) | Gasto adm. Mibanco | Gasto adm. resto | Dif. (pp) |
|---|---|---|---|---|---|---|
| Oct 2025 | 76.1% | 74.5% | +1.6 | 36.1% | 34.3% | +1.9 |
| Nov 2025 | 77.6% | 78.3% | -0.6 | 44.5% | 37.8% | +6.7 |
| Dic 2025 | 81.7% | 79.9% | +1.8 | 40.1% | 39.8% | +0.3 |
| Ene 2026 | 81.5% | 77.9% | +3.6 | 38.5% | 33.1% | +5.4 |
| Feb 2026 | 82.1% | 78.6% | +3.5 | 42.3% | 37.8% | +4.5 |
| Mar 2026 | 77.3% | 70.8% | +6.5 | 36.0% | 31.4% | +4.5 |
| Abr 2026 | 81.3% | 76.0% | +5.4 | 38.1% | 34.0% | +4.0 |
| May 2026 | 87.8% | 88.9% | -1.1 | 39.1% | 39.1% | 0.0 |
| Jun 2026 | 81.8% | 79.4% | +2.5 | 39.0% | 35.7% | +3.3 |
| Jul 2026 | 81.7% | 78.6% | +3.1 | 36.7% | 35.5% | +1.2 |
| Ago 2026 | 80.7% | 78.2% | +2.6 | 36.5% | 35.4% | +1.1 |

### Hallazgos

- El margen financiero bruto de Mibanco fue **mayor que el del resto de la banca en 9 de 11 meses**, con unos **2.6 pp** de ventaja en promedio (máximo de 6.5 pp en marzo 2026).
- Su gasto administrativo sobre ingresos fue **mayor en 10 de 11 meses**, unos **3.0 pp** por encima en promedio.
- **Mayo 2026** muestra un salto del margen en todo el sistema (88.9% en el resto de la banca), no solo en Mibanco, por lo que no es un efecto propio de esta entidad.
- *Hipótesis (no verificada con estos datos):* margen mayor y gasto operativo mayor es un patrón coherente con un modelo de microfinanzas, con muchos créditos pequeños y una red de agencias amplia.

## Limitaciones

- Solo 12 meses y solo banca múltiple: no incluye cajas municipales ni financieras, que son los competidores directos de Mibanco en microfinanzas.
- El margen financiero bruto no descuenta provisiones por incobrabilidad, que son relevantes en microcrédito. Un siguiente paso natural es analizar ROA y ROE y la mora.
- El análisis es descriptivo; no explica las causas de las diferencias entre entidades.

## Nota sobre el desarrollo

Proyecto elaborado con apoyo de una herramienta de inteligencia artificial (Claude) para el diseño de las consultas y del script de carga. Los datos cargados se validaron con controles de consistencia: en todos los meses y entidades, activo = pasivo + patrimonio; el resultado neto del balance coincide con el del estado de ganancias y pérdidas; y el flujo de enero es igual al acumulado de enero.
