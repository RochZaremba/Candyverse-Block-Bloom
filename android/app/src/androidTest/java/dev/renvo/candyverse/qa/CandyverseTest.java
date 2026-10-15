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
        android.content.Context target = InstrumentationRegistry.getInstrumentation().getTargetContext();
        Intent launch = target.getPackageManager().getLaunchIntentForPackage(target.getPackageName());
        if (launch == null || launch.getComponent() == null) {
            throw new IllegalStateException("QA launcher activity is missing");
        }
        try {
            return Class.forName(launch.getComponent().getClassName())
                    .asSubclass(FlutterActivity.class);
        } catch (ClassNotFoundException error) {
            throw new IllegalStateException("QA target activity is missing", error);
        }
    }

    private static <T extends FlutterActivity> ActivityTestRule<T> activityRule(Class<T> type) {
        return new ActivityTestRule<T>(type, true, false) {
                @Override
                protected Intent getActivityIntent() {
                    Intent intent = new Intent(Intent.ACTION_MAIN).setClass(
                            InstrumentationRegistry.getInstrumentation().getTargetContext(), type);
                    if ("true".equals(InstrumentationRegistry.getArguments()
                            .getString("candyverseSoftwareRendering"))) {
                        intent.putExtra(FlutterShellArgs.ARG_KEY_ENABLE_SOFTWARE_RENDERING, true);
                        intent.putExtra(FlutterShellArgs.ARG_KEY_TOGGLE_IMPELLER, false);
                    }
                    return intent;
                }
                @Override
                public T launchActivity(Intent startIntent) {
                    try {
                        return super.launchActivity(startIntent);
                    } catch (RuntimeException error) {
                        // FlutterTestRunner swallows RuntimeException and then waits
                        // forever for Dart results, even when no activity started.
                        throw new AssertionError("Unable to launch Candyverse QA activity", error);
                    }
                }
            };
    }

    @Rule
    public ActivityTestRule<? extends FlutterActivity> rule = activityRule(applicationActivity());
}
