import java.nio.file.*;
import java.nio.file.attribute.PosixFilePermissions;
import java.util.*;
import java.io.*;

/** Local-only bundletool wrapper: secrets never appear in argv, env, or output. */
class BuildCandyverseApks {
  static Path outsideGit(Path source) throws Exception {
    Path resolved = source.toRealPath();
    Path folder = Files.isDirectory(resolved) ? resolved : resolved.getParent();
    Process check = new ProcessBuilder("git", "-C", folder.toString(), "rev-parse", "--is-inside-work-tree")
        .redirectError(ProcessBuilder.Redirect.DISCARD).start();
    String result = new String(check.getInputStream().readAllBytes()).trim();
    if (check.waitFor() == 0 && result.equals("true"))
      throw new IllegalArgumentException("Signing files must be outside Git repositories.");
    return resolved;
  }
  static String required(Properties props, String key) {
    String value = props.getProperty(key);
    if (value == null || value.isBlank() || value.contains("\n") || value.contains("\r"))
      throw new IllegalArgumentException("Missing or invalid signing property: " + key);
    return value;
  }
  public static void main(String[] args) throws Exception {
    if (args.length != 4) throw new IllegalArgumentException("Usage: BuildCandyverseApks.java bundletool.jar external-key.properties input.aab NEW-output.apks");
    Path tool = Path.of(args[0]).toRealPath();
    Path properties = outsideGit(Path.of(args[1]));
    Path bundle = Path.of(args[2]).toRealPath();
    Path output = Path.of(args[3]).toAbsolutePath().normalize();
    if (Files.exists(output)) throw new IllegalArgumentException("Output already exists; refusing overwrite.");
    Properties props = new Properties();
    try (InputStream input = Files.newInputStream(properties)) { props.load(input); }
    Path keyStore = Path.of(required(props, "storeFile"));
    if (!keyStore.isAbsolute()) throw new IllegalArgumentException("Expected an absolute external storeFile.");
    keyStore = outsideGit(keyStore);
    String alias = required(props, "keyAlias");
    String storePassword = required(props, "storePassword");
    String keyPassword = required(props, "keyPassword");
    Path privateDirectory = Files.createTempDirectory(Path.of("/tmp"), "candyverse-password-", PosixFilePermissions.asFileAttribute(PosixFilePermissions.fromString("rwx------")));
    Path storePass = privateDirectory.resolve("store-password");
    Path keyPass = privateDirectory.resolve("key-password");
    Thread cleanup = new Thread(() -> {
      for (Path file : List.of(storePass, keyPass, privateDirectory)) {
        try { Files.deleteIfExists(file); } catch (IOException ignored) {}
      }
    });
    Runtime.getRuntime().addShutdownHook(cleanup);
    int status;
    try {
      for (Path secret : List.of(storePass, keyPass))
        Files.createFile(secret, PosixFilePermissions.asFileAttribute(PosixFilePermissions.fromString("rw-------")));
      Files.writeString(storePass, storePassword + "\n");
      Files.writeString(keyPass, keyPassword + "\n");
      props.clear();
      status = new ProcessBuilder(Path.of(System.getProperty("java.home"), "bin", "java").toString(),
          "-jar", tool.toString(), "build-apks", "--bundle=" + bundle, "--output=" + output,
          "--mode=universal", "--ks=" + keyStore, "--ks-key-alias=" + alias,
          "--ks-pass=file:" + storePass, "--key-pass=file:" + keyPass).inheritIO().start().waitFor();
    } finally {
      Files.deleteIfExists(storePass);
      Files.deleteIfExists(keyPass);
      Files.deleteIfExists(privateDirectory);
      Runtime.getRuntime().removeShutdownHook(cleanup);
    }
    if (status != 0) throw new IOException("bundletool build-apks failed; exit " + status);
    System.out.println("Universal APK set built; temporary password files removed.");
  }
}
