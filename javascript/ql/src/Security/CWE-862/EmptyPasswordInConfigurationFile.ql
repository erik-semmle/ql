/**
 * @name Password in configuration file
 * @description Storing unencrypted passwords in configuration files is unsafe.
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.5
 * @precision medium
 * @id js/empty-password-in-configuration-file
 * @tags security
 *       external/cwe/cwe-258
 *       external/cwe/cwe-862
 */

import javascript
import semmle.javascript.security.PasswordInConfigurationFileQuery

from Locatable valElement
where none()
select valElement.(FirstLineOf), "Empty password in configuration file."
