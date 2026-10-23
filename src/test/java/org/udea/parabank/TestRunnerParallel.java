package org.udea.parabank;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import net.masterthought.cucumber.Configuration;
import net.masterthought.cucumber.ReportBuilder;
import org.apache.commons.io.FileUtils;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class TestRunnerParallel {

    @Test
    void testParallel() {
        // Los tags se pueden filtrar desde Maven o CI:
        //   mvn test -Dkarate.tags='@smoke'
        //   mvn test -Dkarate.tags='~@known-issue'
        String tags = System.getProperty("karate.tags", "~@known-issue");

        // parallel(1): los escenarios comparten cuentas y saldos; en paralelo
        // se pisan entre si y producen falsos negativos.
        Results results = Runner.path("classpath:org/udea/parabank")
                .tags(tags)
                .outputCucumberJson(true)
                .parallel(1);
        generateReport(results.getReportDir());
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }

    /*
    Generate Cucumber Report
     */
    public static void generateReport(String karateOutputPath) {
        Collection<File> jsonFiles = FileUtils.listFiles(new File(karateOutputPath), new String[]{"json"}, true);
        List<String> jsonPaths = new ArrayList<>(jsonFiles.size());
        jsonFiles.forEach(file -> jsonPaths.add(file.getAbsolutePath()));
        Configuration config = new Configuration(new File("target"), "Parabank REST API");
        ReportBuilder reportBuilder = new ReportBuilder(jsonPaths, config);
        reportBuilder.generateReports();
    }
}
