module hunt.framework.task.TaskScheduler;


/**
 * Task scheduler interface that abstracts the scheduling of
 * {@link Runnable Runnables} based on different kinds of triggers.
 *
 * <p>This interface is separate from {@link SchedulingTaskExecutor} since it
 * usually represents for a different kind of backend, i.e. a thread pool with
 * different characteristics and capabilities. Implementations may implement
 * both interfaces if they can handle both kinds of execution characteristics.
 *
 * <p>The 'default' implementation is
 * {@link org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler},
 * wrapping a native {@link java.util.concurrent.ScheduledExecutorService}
 * and adding extended trigger capabilities.
 *
 * <p>This interface is roughly equivalent to a JSR-236
 * {@code ManagedScheduledExecutorService} as supported in Java EE 7
 * environments but aligned with Spring's {@code TaskExecutor} model.
 *
 * @author Juergen Hoeller
 * @since 3.0
 * @see org.springframework.core.task.TaskExecutor
 * @see java.util.concurrent.ScheduledExecutorService
 * @see org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler
 */
interface TaskScheduler {

	// /**
	//  * Schedule the given {@link Runnable}, invoking it whenever the trigger
	//  * indicates a next execution time.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param trigger an implementation of the {@link Trigger} interface,
	//  * e.g. a {@link org.springframework.scheduling.support.CronTrigger} object
	//  * wrapping a cron expression
	//  * @return a {@link ScheduledFuture} representing pending completion of the task,
	//  * or {@code null} if the given Trigger object never fires (i.e. returns
	//  * {@code null} from {@link Trigger#nextExecutionTime})
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  * @see org.springframework.scheduling.support.CronTrigger
	//  */
	// @Nullable
	// ScheduledFuture<?> schedule(Runnable task, Trigger trigger);

	// /**
	//  * Schedule the given {@link Runnable}, invoking it at the specified execution time.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param startTime the desired execution time for the task
	//  * (if this is in the past, the task will be executed immediately, i.e. as soon as possible)
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  * @since 5.0
	//  * @see #schedule(Runnable, Date)
	//  */
	// default ScheduledFuture<?> schedule(Runnable task, Instant startTime) {
	// 	return schedule(task, Date.from(startTime));
	// }

	// /**
	//  * Schedule the given {@link Runnable}, invoking it at the specified execution time.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param startTime the desired execution time for the task
	//  * (if this is in the past, the task will be executed immediately, i.e. as soon as possible)
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  */
	// ScheduledFuture<?> schedule(Runnable task, Date startTime);

	// /**
	//  * Schedule the given {@link Runnable}, invoking it at the specified execution time
	//  * and subsequently with the given period.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param startTime the desired first execution time for the task
	//  * (if this is in the past, the task will be executed immediately, i.e. as soon as possible)
	//  * @param period the interval between successive executions of the task
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if  the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  * @since 5.0
	//  * @see #scheduleAtFixedRate(Runnable, Date, long)
	//  */
	// default ScheduledFuture<?> scheduleAtFixedRate(Runnable task, Instant startTime, Duration period) {
	// 	return scheduleAtFixedRate(task, Date.from(startTime), period.toMillis());
	// }

	// /**
	//  * Schedule the given {@link Runnable}, invoking it at the specified execution time
	//  * and subsequently with the given period.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param startTime the desired first execution time for the task
	//  * (if this is in the past, the task will be executed immediately, i.e. as soon as possible)
	//  * @param period the interval between successive executions of the task (in milliseconds)
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if  the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  */
	// ScheduledFuture<?> scheduleAtFixedRate(Runnable task, Date startTime, long period);

	// /**
	//  * Schedule the given {@link Runnable}, starting as soon as possible and
	//  * invoking it with the given period.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param period the interval between successive executions of the task
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  * @since 5.0
	//  * @see #scheduleAtFixedRate(Runnable, long)
	//  */
	// default ScheduledFuture<?> scheduleAtFixedRate(Runnable task, Duration period) {
	// 	return scheduleAtFixedRate(task, period.toMillis());
	// }

	// /**
	//  * Schedule the given {@link Runnable}, starting as soon as possible and
	//  * invoking it with the given period.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param period the interval between successive executions of the task (in milliseconds)
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  */
	// ScheduledFuture<?> scheduleAtFixedRate(Runnable task, long period);

	// /**
	//  * Schedule the given {@link Runnable}, invoking it at the specified execution time
	//  * and subsequently with the given delay between the completion of one execution
	//  * and the start of the next.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param startTime the desired first execution time for the task
	//  * (if this is in the past, the task will be executed immediately, i.e. as soon as possible)
	//  * @param delay the delay between the completion of one execution and the start of the next
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  * @since 5.0
	//  * @see #scheduleWithFixedDelay(Runnable, Date, long)
	//  */
	// default ScheduledFuture<?> scheduleWithFixedDelay(Runnable task, Instant startTime, Duration delay) {
	// 	return scheduleWithFixedDelay(task, Date.from(startTime), delay.toMillis());
	// }

	// /**
	//  * Schedule the given {@link Runnable}, invoking it at the specified execution time
	//  * and subsequently with the given delay between the completion of one execution
	//  * and the start of the next.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param startTime the desired first execution time for the task
	//  * (if this is in the past, the task will be executed immediately, i.e. as soon as possible)
	//  * @param delay the delay between the completion of one execution and the start of the next
	//  * (in milliseconds)
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  */
	// ScheduledFuture<?> scheduleWithFixedDelay(Runnable task, Date startTime, long delay);

	// /**
	//  * Schedule the given {@link Runnable}, starting as soon as possible and invoking it with
	//  * the given delay between the completion of one execution and the start of the next.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param delay the delay between the completion of one execution and the start of the next
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  * @since 5.0
	//  * @see #scheduleWithFixedDelay(Runnable, long)
	//  */
	// default ScheduledFuture<?> scheduleWithFixedDelay(Runnable task, Duration delay) {
	// 	return scheduleWithFixedDelay(task, delay.toMillis());
	// }

	// /**
	//  * Schedule the given {@link Runnable}, starting as soon as possible and invoking it with
	//  * the given delay between the completion of one execution and the start of the next.
	//  * <p>Execution will end once the scheduler shuts down or the returned
	//  * {@link ScheduledFuture} gets cancelled.
	//  * @param task the Runnable to execute whenever the trigger fires
	//  * @param delay the delay between the completion of one execution and the start of the next
	//  * (in milliseconds)
	//  * @return a {@link ScheduledFuture} representing pending completion of the task
	//  * @throws org.springframework.core.task.TaskRejectedException if the given task was not accepted
	//  * for internal reasons (e.g. a pool overload handling policy or a pool shutdown in progress)
	//  */
	// ScheduledFuture<?> scheduleWithFixedDelay(Runnable task, long delay);

}
