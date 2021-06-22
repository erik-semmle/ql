/**
 * @name Promise definitions
 * @description Selects all promise definitions.
 * @kind problem
 * @metricType project
 * @metricAggregate sum
 * @tags meta
 * @id js/meta/promise-definitions
 */

import javascript
import meta.MetaMetrics

from PromiseDefinition p
select p, "promise"
