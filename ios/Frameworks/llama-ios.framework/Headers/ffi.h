#ifndef FFI_H
#define FFI_H

#ifdef __cplusplus
extern "C"
{
#endif

// Framework version
#define MOBILE_LLM_VERSION "1.0.0"

    /**
     * Start a chat session with the specified model and parameters.
     *
     * @param local_model_path Path to the local model file
     * @param system_prompt Initial system prompt to set the context
     * @param thread_num Number of threads to use for inference
     * @param sendString Callback function to send string output
     * @param sendStat Callback function to send progress statistics
     */
    void startChat(
        const char *local_model_path,
        const char *system_prompt,
        int thread_num,
        void (*sendString)(const char *s),
        void (*sendStat)(float a, float b));

    /**
     * Start a chat session with the specified model and parameters.
     *
     * @param local_model_path Path to the local model file
     * @param system_prompt Initial system prompt to set the context
     * @param thread_num Number of threads to use for inference
     * @param thread_num_prefetch Number of prefetch threads to use for inference
     * @param mem_size Memory size to use for inference
     * @param context_size Context size to use for inference
     * @param sendString Callback function to send string output
     * @param sendStat Callback function to send progress statistics
     */
    void startChatWPrefetch(
        const char *local_model_path,
        const char *system_prompt,
        int thread_num,
        int thread_num_prefetch,
        float mem_size,
        int context_size,
        void (*sendString)(const char *s),
        void (*sendStat)(float a, float b));

    /**
     * Stop the ongoing chat session.
     */
    void stopChat();

    /**
     * Start a benchmarking session for one or more models.
     *
     * @param local_model_path Array of paths to local model files
     * @param num_models Number of models in the local_model_path array
     * @param thread_num Number of threads to use for inference
     * @param prompt_length Length of prompt to use for benchmarking
     * @param generation_size Number of tokens to generate for benchmarking
     * @param tasks Array of task names to benchmark (e.g., "perplexity")
     * @param num_tasks Number of tasks in the tasks array
     * @param sendResult Callback function to send benchmark results as JSON string
     */
    void startBenchmark(
        const char *local_model_path,
        int thread_num,
        int thread_num_prefetch,
        float mem_size,
        int context_size,
        int prompt_length,
        int generation_size,
        const char **tasks,
        int num_tasks,
        const char *perplexity_file,
        void (*sendResult)(const char *s));

    /**
     * Input a string to the ongoing chat session.
     *
     * @param s Input string to process
     */
    void inputString(const char *s);

#ifdef __cplusplus
}
#endif

#endif // FFI_H
