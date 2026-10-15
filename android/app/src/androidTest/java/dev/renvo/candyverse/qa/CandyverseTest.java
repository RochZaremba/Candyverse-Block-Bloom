package dev.renvo.candyverse.qa;

import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import io.flutter.embedding.android.FlutterActivity;
import org.junit.Rule;
import org.junit.runner.RunWith;

/** SDK-supported native runner; no host VMService connection is required. */
@RunWith(FlutterTestRunner.class)
public class CandyverseTest {
    private static Class<? extends FlutterActivity> applicationActivity() {
        String packageName = InstrumentationRegistry.getInstrumentation()
                .getTargetContext().getPackageName();
        try {
            return Class.forName(packageName + ".MainActivity")
                    .asSubclass(FlutterActivity.class);
        } catch (ClassNotFoundException error) {
            throw new IllegalStateException("QA target activity is missing", error);
        }
    }

    @Rule
    public ActivityTestRule<? extends FlutterActivity> rule =
            new ActivityTestRule<>(applicationActivity(), true, false);
}
