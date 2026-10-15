package dev.renvo.candyverse.qa;

import android.content.Intent;
import io.flutter.embedding.engine.FlutterShellArgs;
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

    private static <T extends FlutterActivity> ActivityTestRule<T> activityRule(Class<T> type) {
        return new ActivityTestRule<T>(type, true, false) {
                @Override
                protected Intent getActivityIntent() {
                    Intent intent = super.getActivityIntent();
                    if ("true".equals(InstrumentationRegistry.getArguments()
                            .getString("candyverseSoftwareRendering"))) {
                        intent.putExtra(FlutterShellArgs.ARG_KEY_ENABLE_SOFTWARE_RENDERING, true);
                        intent.putExtra(FlutterShellArgs.ARG_KEY_TOGGLE_IMPELLER, false);
                    }
                    return intent;
                }
            };
    }

    @Rule
    public ActivityTestRule<? extends FlutterActivity> rule = activityRule(applicationActivity());
}
