/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.file.UploadedFile;

import hunt.framework.file.File;
import hunt.framework.Simplify;

class UploadedFile : File
{
    private int _errorCode = 0;
    private string _errorMessage = "Unknow error.";
    private string _originalName;
    private string _mimeType;

    /**
     * Accepts the information of the uploaded file as provided by the PHP global $_FILES.
     *
     * The file object is only created when the uploaded file is valid (i.e. when the
     * isValid() method returns true). Otherwise the only methods that could be called
     * on an UploadedFile instance are:
     *
     *   * getClientOriginalName,
     *   * getClientMimeType,
     *   * isValid,
     *   * getError.
     *
     * Calling any other method on an non-valid instance will cause an unpredictable result.
     *
     * @param string      $path         The full temporary path to the file
     * @param string      $originalName The original file name of the uploaded file
     * @param string|null $mimeType     The type of the file as provided by PHP; null defaults to application/octet-stream
     * @param int|null    $error        The error constant of the upload (one of PHP's UPLOAD_ERR_XXX constants); null defaults to UPLOAD_ERR_OK
     * @param bool        $test         Whether the test mode is active
     *                                  Local files are used in test mode hence the code should not enforce HTTP uploads
     *
     * @throws FileException         If file_uploads is disabled
     * @throws FileNotFoundException If the file does not exist
     */
    public this(string path, string originalName, string mimeType = null, int errorCode = 0)
    {
        this._originalName = this.getName(originalName);
        this._mimeType = mimeType is null ? "application/octet-stream" : mimeType;
        this._errorCode = errorCode;
        
        super(path);
    }

    /**
     * Returns the original file name.
     *
     * It is extracted from the request from which the file has been uploaded.
     * Then it should not be considered as a safe value.
     *
     * @return string|null The original name
     */
    public string originalName()
    {
        return this._originalName;
    }

    /**
     * Returns the original file extension.
     *
     * It is extracted from the original file name that was uploaded.
     * Then it should not be considered as a safe value.
     *
     * @return string The extension
     */
    override public string extension()
    {
        import std.string : lastIndexOf, replace;

        string extensionName;

        extensionName = this.path().replace("\\", "/");
        extensionName = extensionName[lastIndexOf(extensionName, '/')..$];
        
        return extensionName;
    }

    /**
     * Returns the file mime type.
     *
     * The client mime type is extracted from the request from which the file
     * was uploaded, so it should not be considered as a safe value.
     *
     * For a trusted mime type, use getMimeType() instead (which guesses the mime
     * type based on the file content).
     *
     * @return string|null The mime type
     *
     * @see getMimeType()
     */
    override public string mimeType()
    {
        return this._mimeType;
    }

    /**
     * Returns the upload error.
     *
     * If the upload was successful, the constant UPLOAD_ERR_OK is returned.
     * Otherwise one of the other UPLOAD_ERR_XXX constants is returned.
     *
     * @return int The upload error
     */
    public int getErrorCode()
    {
        return this._errorCode;
    }

    /**
     * Returns whether the file was uploaded successfully.
     *
     * @return bool True if the file has been uploaded with HTTP and no error occurred
     */
    public bool isValid()
    {
        return !this._errorCode;
    }

    /**
     * Returns the maximum size of an uploaded file as configured in php.ini.
     *
     * @return int The maximum size of an uploaded file in bytes
     */
    public static long maxSize()
    {
        return config().upload.maxSize;
    }

    /**
     * Store the uploaded file on a filesystem disk.
     *
     * @param  string  path
     * @return false
     */
    public bool store(string path)
    {
        return this.move(path);
    }

    /**
     * Returns an informative upload error message.
     *
     * @return string The error message regarding the specified error code
     */
    public string getErrorMessage()
    {
        // static $errors = [
        //     UPLOAD_ERR_INI_SIZE => 'The file "%s" exceeds your upload_max_filesize ini directive (limit is %d KiB).',
        //     UPLOAD_ERR_FORM_SIZE => 'The file "%s" exceeds the upload limit defined in your form.',
        //     UPLOAD_ERR_PARTIAL => 'The file "%s" was only partially uploaded.',
        //     UPLOAD_ERR_NO_FILE => 'No file was uploaded.',
        //     UPLOAD_ERR_CANT_WRITE => 'The file "%s" could not be written on disk.',
        //     UPLOAD_ERR_NO_TMP_DIR => 'File could not be uploaded: missing temporary directory.',
        //     UPLOAD_ERR_EXTENSION => 'File upload was stopped by a PHP extension.',
        // ];

        // $errorCode = this._errorCode;
        // $maxFilesize = UPLOAD_ERR_INI_SIZE === $errorCode ? self::getMaxFilesize() / 1024 : 0;
        // $message = isset($errors[$errorCode]) ? $errors[$errorCode] : 'The file "%s" was not uploaded due to an unknown error.';
        // return sprintf($message, this.getClientOriginalName(), $maxFilesize);

        return this._errorMessage;
    }
}
