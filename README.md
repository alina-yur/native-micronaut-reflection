# Native Micronaut 👩‍🚀

## Getting Started

Go to [micronaut.io/launch](https://micronaut.io/launch/) and generate your project. You might want to pay attention to defaults — I chose latest Java, Maven, and JUnit. For the sake of this project, our demo will be called `library`.

For now we are not adding any dependencies — support for GraalVM Native Image is already implicitly included out of the box.

Build and run the app on the JVM:

```shell
mvn mn:run
```

Build and run the app as a native image:

```shell
mvn package -Dpackaging=native-image
./target/library
```

## The Application

Now let's design our application. It will be a home library application, containing books and exposing several endpoints to retrieve them. For that, we added Library and Book classes, and a Controller, Service, and Repository to work with the data and interact with the user.

## Working with a Database

The Micronaut team highly encourages using [Flyway](https://micronaut-projects.github.io/micronaut-flyway/latest/guide/) for managing database schemas. Note that flyway migrations require full control over schema management. If you manually configure `datasources.default.schema-generate`, such as set it to `CREATE_DROP`, set it to `NONE` to ensure that only Flyway manages your schema.

### MySQL

For the MySQL settings and config, go to the `mysql-experiments` branch.
https://github.com/micronaut-projects/micronaut-data


## Reflection

For cases where you have custom reflection code, and Native Image isn't able to resolve it auotmatically, the best solution is to use programmatic reflection configuration. In Micronaut, use the ` @ReflectConfig` annotation. For example:

```java
package example.micronaut;

import io.micronaut.core.annotation.ReflectionConfig;

@ReflectionConfig(
        type = StringReverser.class,
        methods = {
                @ReflectionConfig.ReflectiveMethodConfig(name = "reverse", parameterTypes = {String.class})
        }
)

public class NativeImageConfig {
}
```



To do

[] try running MySQL via Rancher
[] different app properties for h2 and mysql (what about the annotations then)?
[] SBOM: The Micronaut Gradle plugin applies the Micronaut Bill of Materials (BOM). However, if you were applying the BOM directly to your build. You should use io.micronaut.platform:micronaut-platform.
